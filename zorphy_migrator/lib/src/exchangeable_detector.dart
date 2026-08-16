import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'model.dart';

/// Locates custom codegen model classes via resolved AST analysis — the
/// non-freezed dialect used by fork packages such as zikzak_inappwebview /
/// flutter_inappwebview (`@ExchangeableObject()` value objects and
/// `@ExchangeableEnum()` class-based enums from their internal annotations
/// package).
///
/// Unlike [FreezedDetector] (which resolves annotations to
/// `package:freezed_annotation`), the annotation match is by simple name —
/// `ExchangeableObject` / `ExchangeableEnum` are distinctive and this keeps
/// the tool usable for ANY package using that annotation naming, regardless
/// of which library provides it.
class ExchangeableDetector {
  static const _objectAnnotation = 'ExchangeableObject';
  static const _enumAnnotation = 'ExchangeableEnum';

  /// Member annotations that add custom codegen surface we cannot express as
  /// a Zorphy value object — reported as manual, never silently dropped.
  static const _customMemberAnnotations = {
    'ExchangeableObjectMethod',
    'ExchangeableObjectProperty',
    'ExchangeableObjectConstructor',
  };

  /// Analyzes [filePaths] (absolute) and returns detected exchangeable
  /// classes/enums as models with [ModelDialect.exchangeableObject] /
  /// [ModelDialect.exchangeableEnum].
  Future<List<FreezedClassModel>> detect(List<String> filePaths) async {
    if (filePaths.isEmpty) return const [];

    final roots = <String>{
      for (final f in filePaths) p.dirname(f),
    }.toList();

    final collection = AnalysisContextCollection(
      includedPaths: roots,
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    final results = <FreezedClassModel>[];
    for (final file in filePaths) {
      final context = collection.contextFor(file);
      final unitResult = await context.currentSession.getResolvedUnit(file);
      if (unitResult is! ResolvedUnitResult) continue;
      results.addAll(_detectInUnit(unitResult));
    }
    return results;
  }

  List<FreezedClassModel> _detectInUnit(ResolvedUnitResult unit) {
    final found = <FreezedClassModel>[];
    for (final declaration in unit.unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      final dialect = _dialectOf(declaration);
      if (dialect == null) continue;
      found.add(_buildModel(declaration, dialect, unit));
    }
    return found;
  }

  ModelDialect? _dialectOf(ClassDeclaration node) {
    var isObject = false;
    var isEnum = false;
    for (final meta in node.metadata) {
      final name = _annotationSimpleName(meta);
      if (name == _objectAnnotation) isObject = true;
      if (name == _enumAnnotation) isEnum = true;
    }
    if (isObject) return ModelDialect.exchangeableObject;
    if (isEnum) return ModelDialect.exchangeableEnum;
    return null;
  }

  /// Simple (unprefixed) annotation name, e.g. `Foo` for `@Foo()` and for
  /// `@lib.Foo()`.
  String? _annotationSimpleName(Annotation annotation) {
    final name = annotation.name;
    if (name is PrefixedIdentifier) return name.identifier.name;
    return name.name;
  }

  FreezedClassModel _buildModel(
    ClassDeclaration node,
    ModelDialect dialect,
    ResolvedUnitResult unit,
  ) {
    final LineInfo lineInfo = unit.lineInfo;
    final manual = <ManualItem>[];
    final name = _stripSuffix(node.namePart.typeName.lexeme);
    final typeParams =
        node.namePart.typeParameters?.typeParameters
            .map((t) => t.name.lexeme)
            .toList() ??
        const <String>[];

    final body = node.body;
    final members = body is BlockClassBody
        ? body.members
        : const <ClassMember>[];

    final doc = node.documentationComment?.tokens
        .map((t) => t.lexeme)
        .join('\n');

    if (dialect == ModelDialect.exchangeableObject) {
      return _buildObjectModel(
        node,
        unit,
        lineInfo,
        manual,
        name,
        typeParams,
        members,
        doc,
      );
    }
    return _buildEnumModel(
      node,
      unit,
      lineInfo,
      manual,
      name,
      typeParams,
      members,
      doc,
    );
  }

  FreezedClassModel _buildObjectModel(
    ClassDeclaration node,
    ResolvedUnitResult unit,
    LineInfo lineInfo,
    List<ManualItem> manual,
    String name,
    List<String> typeParams,
    List<ClassMember> members,
    String? doc,
  ) {
    final fields = <FreezedField>[];
    final constructorParamNames = <String>{};
    final staticMethods = <String>[];
    final informational = <ManualItem>[];

    // Field declarations carry the docs and (for `this.x` params) the type;
    // index them by name for the constructor pass below.
    final fieldDecls = <String, FieldDeclaration>{};
    for (final member in members) {
      if (member is! FieldDeclaration) continue;
      for (final variable in member.fields.variables) {
        fieldDecls[variable.name.lexeme] = member;
      }
    }

    // 1. Collect fields from the (generative) constructor's parameters.
    for (final member in members) {
      if (member is! ConstructorDeclaration) continue;
      if (member.factoryKeyword != null) continue; // not a generative ctor
      // `@ExchangeableObjectConstructor` is the fork codegen's standard
      // constructor marker; it only adds custom surface when the body has
      // statements (e.g. asserts, default computation). An empty body
      // (`{}` / `;`) means the parameters alone define the field set, so the
      // constructor is convertible like a plain generative one.
      if (_hasCustomMemberAnnotation(member) &&
          !_isEmptyBody(member.body)) {
        manual.add(
          ManualItem(
            filePath: unit.path,
            line: lineInfo.getLocation(member.offset).lineNumber,
            construct: name,
            reason: 'custom @ExchangeableObjectConstructor — migrate by hand',
          ),
        );
        continue;
      }
      for (final param in member.parameters.parameters) {
        final paramName = param.name?.lexeme;
        if (paramName == null) continue;
        constructorParamNames.add(paramName);
        final fieldDecl = fieldDecls[paramName];
        fields.add(
          FreezedField(
            name: paramName,
            type: _paramType(param, members) ?? 'dynamic',
            isRequired: param.isRequired,
            defaultExpression: param.defaultClause?.value.toSource(),
            docComment: _fieldDoc(fieldDecl, paramName),
          ),
        );
      }
    }

    // 2. Everything else in the body is manual (never silently dropped):
    //    custom methods, custom-annotation members, and instance fields that
    //    are not constructor parameters.
    for (final member in members) {
      if (member is ConstructorDeclaration) continue;
      if (member is MethodDeclaration) {
        if (member.isStatic && _returnsOwnType(member, name)) {
          // Capture verbatim from the start of the member's line (or its doc
          // comment) so the re-emitted factory keeps its original
          // indentation and documentation.
          var start = member.beginToken.precedingComments?.offset ?? member.offset;
          while (start > 0 && unit.content[start - 1] != '\n') {
            start--;
          }
          staticMethods.add(
            unit.content.substring(start, member.end),
          );
          informational.add(
            ManualItem(
              filePath: unit.path,
              line: lineInfo.getLocation(member.offset).lineNumber,
              construct: '$name.${member.name.lexeme}',
              reason:
                  'static factory returning $name — preserved verbatim on '
                  'the migrated \$ class (zorphy generator re-emits it on '
                  'the concrete class)',
            ),
          );
          continue;
        }
        manual.add(
          ManualItem(
            filePath: unit.path,
            line: lineInfo.getLocation(member.offset).lineNumber,
            construct: '$name.${member.name.lexeme}',
            reason:
                'custom ${member.isGetter ? 'getter' : 'method'} in class '
                'body — never silently dropped, migrate by hand',
          ),
        );
        continue;
      }
      if (_hasCustomMemberAnnotation(member)) {
        manual.add(
          ManualItem(
            filePath: unit.path,
            line: lineInfo.getLocation(member.offset).lineNumber,
            construct: name,
            reason: 'custom @ExchangeableObjectMethod/@ExchangeableObjectProperty '
                'member — migrate by hand',
          ),
        );
        continue;
      }
      if (member is FieldDeclaration) {
        if (member.isStatic) continue;
        for (final variable in member.fields.variables) {
          if (variable.isConst) continue;
          final fieldName = variable.name.lexeme;
          if (!constructorParamNames.contains(fieldName)) {
            manual.add(
              ManualItem(
                filePath: unit.path,
                line: lineInfo.getLocation(variable.offset).lineNumber,
                construct: '$name.$fieldName',
                reason: 'instance field not a constructor parameter — '
                    'migrate by hand',
              ),
            );
          }
        }
      }
    }

    return FreezedClassModel(
      name: name,
      filePath: unit.path,
      typeParameters: typeParams,
      fields: fields,
      variants: const [],
      hasFromJson: true,
      hasToJson: false,
      isUnfreezed: false,
      manualItems: manual,
      spanStart: node.offset,
      spanEnd: node.end,
      docComment: doc,
      dialect: ModelDialect.exchangeableObject,
      informationalItems: informational,
      staticMethods: staticMethods,
    );
  }

  FreezedClassModel _buildEnumModel(
    ClassDeclaration node,
    ResolvedUnitResult unit,
    LineInfo lineInfo,
    List<ManualItem> manual,
    String name,
    List<String> typeParams,
    List<ClassMember> members,
    String? doc,
  ) {
    final enumMembers = <String>[];
    final enumMemberDocs = <String?>[];
    final intValues = <int>[];

    // Wire mismatches do NOT block the enum conversion (names/order are
    // preserved; only the consumer glue needs hand attention), so they are
    // reported as informational items on the converted model.
    final informational = <ManualItem>[];

    for (final member in members) {
      if (member is! FieldDeclaration) continue;
      for (final variable in member.fields.variables) {
        if (!variable.isConst) continue;
        final memberName = variable.name.lexeme;
        enumMembers.add(memberName);
        enumMemberDocs.add(
          variable.documentationComment?.tokens
              .map((t) => t.lexeme)
              .join('\n'),
        );

        final initializer = variable.initializer?.toSource() ?? '';
        final match = RegExp(
          r'_internal\(\s*([^)]+?)\s*\)',
        ).firstMatch(initializer);
        final arg = match?.group(1)?.trim();
        if (arg == null) continue;
        final intValue = int.tryParse(arg);
        if (intValue != null) {
          intValues.add(intValue);
        } else if (arg.startsWith("'") || arg.startsWith('"')) {
          // String wire value — keep the member name; a differing wire
          // string needs hand glue in the entity's @JsonKey.
          if (arg != "'$memberName'" && arg != '"$memberName"') {
            informational.add(
              ManualItem(
                filePath: unit.path,
                line: lineInfo.getLocation(variable.offset).lineNumber,
                construct: '$name.$memberName',
                reason:
                    'enum wire value $arg differs from the member name — '
                    'string-wire glue by hand',
              ),
            );
          }
        }
      }
    }

    // int-wire enums: `.index` only matches the old `_value` when values are
    // exactly 0..n-1 in declaration order.
    if (intValues.isNotEmpty &&
        !_isSequential(intValues)) {
      informational.add(
        ManualItem(
          filePath: unit.path,
          line: lineInfo.getLocation(node.offset).lineNumber,
          construct: name,
          reason:
              'enum int wire values ${intValues.join(', ')} are not '
              'sequential 0..n-1 — plain `.index` no longer matches the old '
              '_value; int-wire glue by hand',
        ),
      );
    }

    return FreezedClassModel(
      name: name,
      filePath: unit.path,
      typeParameters: typeParams,
      fields: const [],
      variants: const [],
      hasFromJson: false,
      hasToJson: false,
      isUnfreezed: false,
      manualItems: manual,
      informationalItems: informational,
      spanStart: node.offset,
      spanEnd: node.end,
      docComment: doc,
      dialect: ModelDialect.exchangeableEnum,
      enumMembers: enumMembers,
      enumMemberDocs: enumMemberDocs,
    );
  }

  bool _isSequential(List<int> values) {
    for (var i = 0; i < values.length; i++) {
      if (values[i] != i) return false;
    }
    return true;
  }

  bool _hasCustomMemberAnnotation(ClassMember member) {
    for (final meta in member.metadata) {
      final annotationName = _annotationSimpleName(meta);
      if (annotationName != null &&
          _customMemberAnnotations.contains(annotationName)) {
        return true;
      }
    }
    return false;
  }

  /// Whether [body] contains no statements — `;` or an empty `{}` block.
  bool _isEmptyBody(FunctionBody body) {
    if (body is EmptyFunctionBody) return true;
    if (body is BlockFunctionBody) return body.block.statements.isEmpty;
    return false;
  }

  /// The declared type of a constructor parameter. For `this.x` params the
  /// param node carries no type, so fall back to the matching field
  /// declaration in the class body.
  String? _paramType(
    FormalParameter param,
    List<ClassMember> members,
  ) {
    final elementType = param.declaredFragment?.element.type;
    if (elementType != null) return elementType.getDisplayString();

    final fieldName = param.name?.lexeme;
    if (fieldName == null) return null;
    for (final member in members) {
      if (member is! FieldDeclaration) continue;
      for (final variable in member.fields.variables) {
        if (variable.name.lexeme != fieldName) continue;
        final fieldType = variable.declaredFragment?.element.type;
        if (fieldType != null) return fieldType.getDisplayString();
        return member.fields.type?.toSource();
      }
    }
    return null;
  }

  /// Doc-comment source of the named variable in [decl], or `null`.
  String? _fieldDoc(FieldDeclaration? decl, String name) {
    if (decl == null) return null;
    for (final variable in decl.fields.variables) {
      if (variable.name.lexeme != name) continue;
      return variable.documentationComment?.tokens
          .map((t) => t.lexeme)
          .join('\n');
    }
    return null;
  }

  /// Whether [member] is a static method whose (unqualified, `_`-stripped)
  /// return type is the class's own name — i.e. a convenience factory the
  /// zorphy generator re-emits on the generated concrete class.
  bool _returnsOwnType(MethodDeclaration member, String name) {
    final returnType = member.returnType;
    if (returnType is! NamedType) return false;
    final typeName = returnType.name;
    if (typeName is PrefixedIdentifier) return false;
    return _stripSuffix(typeName.lexeme) == name;
  }

  /// Strips the fork's codegen `_` suffix: `NavigationAction_` →
  /// `NavigationAction`. Names without a trailing underscore pass through
  /// unchanged.
  String _stripSuffix(String name) =>
      name.endsWith('_') ? name.substring(0, name.length - 1) : name;
}
