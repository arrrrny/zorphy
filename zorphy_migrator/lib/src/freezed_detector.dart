import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'model.dart';

/// Locates freezed classes via RESOLVED AST analysis (no regex).
///
/// Detects `@freezed`, `@Freezed`, and `@unfreezed` by resolving each
/// annotation's constant value to `package:freezed_annotation`, so aliases
/// and prefixed imports are handled correctly.
class FreezedDetector {
  static const _freezedPkg = 'package:freezed_annotation';

  /// Analyzes [filePaths] (absolute) and returns detected freezed classes.
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
      final kind = _freezedKind(declaration);
      if (kind == _FreezedKind.none) continue;
      found.add(_buildModel(declaration, kind, unit));
    }
    return found;
  }

  FreezedClassModel _buildModel(
    ClassDeclaration node,
    _FreezedKind kind,
    ResolvedUnitResult unit,
  ) {
    final filePath = unit.path;
    final LineInfo lineInfo = unit.lineInfo;
    final manual = <ManualItem>[];
    final name = node.namePart.typeName.lexeme;
    final typeParams =
        node.namePart.typeParameters?.typeParameters
            .map((t) => t.name.lexeme)
            .toList() ??
        const <String>[];

    final fields = <FreezedField>[];
    final variants = <UnionVariant>[];
    var hasFromJson = false;
    var hasToJson = false;

    final body = node.body;
    final members = body is BlockClassBody
        ? body.members
        : const <ClassMember>[];

    for (final member in members) {
      if (member is! ConstructorDeclaration) {
        if (member is MethodDeclaration) {
          manual.add(
            ManualItem(
              filePath: filePath,
              line: lineInfo.getLocation(member.offset).lineNumber,
              construct: '$name.${member.name.lexeme}',
              reason:
                  'custom ${member.isGetter ? 'getter' : 'method'} in class '
                  'body — never silently dropped, migrate by hand',
            ),
          );
        }
        continue;
      }

      if (member.factoryKeyword == null) {
        manual.add(
          ManualItem(
            filePath: filePath,
            line: lineInfo.getLocation(member.offset).lineNumber,
            construct: '$name.${member.name?.lexeme ?? '(unnamed)'}',
            reason: 'non-factory constructor — migrate by hand',
          ),
        );
        continue;
      }

      final factoryName = member.name?.lexeme;

      // fromJson detection: factory Foo.fromJson(...) => _$FooFromJson(...)
      if (factoryName == 'fromJson') {
        hasFromJson = true;
        continue;
      }

      final redirect = member.redirectedConstructor;
      final redirectTypeName = redirect?.type.name.lexeme;
      final isUnionVariant =
          factoryName != null &&
          redirect != null &&
          redirectTypeName != '_$name';

      final params = _readParams(member, filePath, lineInfo, manual);

      if (isUnionVariant) {
        variants.add(
          UnionVariant(
            className: redirectTypeName!,
            factoryName: factoryName,
            fields: params,
          ),
        );
      } else {
        // Core `= _Foo;` factory — the data fields.
        fields.addAll(params);
      }
    }

    // @Freezed(toJson: true) style options
    for (final meta in node.metadata) {
      final obj = meta.elementAnnotation?.computeConstantValue();
      if (obj == null) continue;
      if (obj.getField('toJson')?.toBoolValue() == true) hasToJson = true;
    }

    if (kind == _FreezedKind.unfreezed) {
      manual.add(
        ManualItem(
          filePath: filePath,
          line: lineInfo.getLocation(node.offset).lineNumber,
          construct: name,
          reason: '@unfreezed mutable model — zorphy is immutable-first; '
              'migrate by hand',
        ),
      );
    }

    final doc = node.documentationComment?.tokens
        .map((t) => t.lexeme)
        .join('\n');

    return FreezedClassModel(
      name: name,
      filePath: filePath,
      typeParameters: typeParams,
      fields: fields,
      variants: variants,
      hasFromJson: hasFromJson,
      hasToJson: hasToJson,
      isUnfreezed: kind == _FreezedKind.unfreezed,
      manualItems: manual,
      spanStart: node.offset,
      spanEnd: node.end,
      docComment: doc,
    );
  }

  List<FreezedField> _readParams(
    ConstructorDeclaration member,
    String filePath,
    LineInfo lineInfo,
    List<ManualItem> manual,
  ) {
    final fields = <FreezedField>[];
    for (final param in member.parameters.parameters) {
      final paramName = param.name?.lexeme;
      if (paramName == null) continue;

      final element = param.declaredFragment?.element;
      final type = element != null
          ? element.type.getDisplayString()
          : 'dynamic';

      String? defaultExpr;
      final jsonKeys = <String>[];

      for (final meta in param.metadata) {
        final obj = meta.elementAnnotation?.computeConstantValue();
        if (obj == null) continue;
        final typeName = obj.type?.getDisplayString();
        final uri = obj.type?.element?.library?.firstFragment.source.uri
            .toString();
        final src = meta.toSource();
        if (typeName == 'Default' &&
            (uri?.startsWith(_freezedPkg) ?? false)) {
          defaultExpr =
              RegExp(r'^@Default\((.*)\)$', dotAll: true)
                  .firstMatch(src)
                  ?.group(1) ??
              src;
        } else if (typeName == 'JsonKey') {
          jsonKeys.add(src);
        }
      }

      if (defaultExpr != null && defaultExpr.contains(paramName)) {
        manual.add(
          ManualItem(
            filePath: filePath,
            line: lineInfo.getLocation(param.offset).lineNumber,
            construct: paramName,
            reason: '@Default expression references its own field — '
                'migrate by hand',
          ),
        );
      }

      fields.add(
        FreezedField(
          name: paramName,
          type: type,
          isRequired: param.isRequired,
          defaultExpression: defaultExpr,
          jsonKeyAnnotations: jsonKeys,
        ),
      );
    }
    return fields;
  }

  _FreezedKind _freezedKind(ClassDeclaration node) {
    var result = _FreezedKind.none;
    for (final meta in node.metadata) {
      final obj = meta.elementAnnotation?.computeConstantValue();
      if (obj == null) continue;
      final uri = obj.type?.element?.library?.firstFragment.source.uri
          .toString();
      if (uri == null || !uri.startsWith(_freezedPkg)) continue;
      final typeName = obj.type?.getDisplayString();
      if (typeName == 'Unfreezed') return _FreezedKind.unfreezed;
      if (typeName == 'Freezed') {
        // `@unfreezed` is `const Freezed(equal: false, ...)` in
        // freezed_annotation 3.x — distinguish via the `equal` field.
        if (obj.getField('equal')?.toBoolValue() == false) {
          return _FreezedKind.unfreezed;
        }
        result = _FreezedKind.freezed;
      }
    }
    return result;
  }
}

enum _FreezedKind { none, freezed, unfreezed }
