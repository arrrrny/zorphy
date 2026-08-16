import 'model.dart';

/// Renders a [FreezedClassModel] as zorphy source text.
///
/// Mapping (pre-decided in the v2.0 spec):
/// - simple class → `@Zorphy() abstract class $Foo { T get x; }`
/// - union → sealed `$$Foo` base + `$Variant implements $$Foo` subtypes
/// - fromJson/toJson → `generateJson: true`
/// - `@Default(expr)` → `abstract class $Foo_` + top-level factory fn
/// - `@JsonKey(...)` → preserved verbatim on the getter
/// - lean-eligible classes → `preset: ZorphyPreset.lean`
/// - field types referencing other migrated classes are rewritten to
///   zorphy's `$`-prefixed form (`Address` → `$Address`,
///   `List<CartItem>` → `List<$CartItem>`)
///
/// `@ExchangeableObject` / `@ExchangeableEnum` dialect (the custom codegen
/// annotations used by flutter_inappwebview forks):
/// - value object → `@Zorphy(kind: ZorphyKind.valueObject, generateJson:
///   true, generateCompareTo: true) abstract class $Foo { T get x; }`
/// - constructor `= expr` defaults → `@JsonKey(defaultValue: expr)` on the
///   getter
/// - class/enum name `Foo_` → `$Foo` / `enum Foo`
/// - field types referencing other classes converted in the same run lose
///   the codegen `_` suffix (`URLRequest_` → `URLRequest`) — the concrete
///   sibling form the generator recovers from source (zorphy #351)
/// - class-based enum → plain Dart `enum Foo { A, B, C }`
class ZorphyRenderer {
  /// Names of freezed classes being migrated alongside — their references
  /// in field types get the `$` prefix.
  final Set<String> siblingClassNames;

  /// Creates a renderer. [siblingClassNames] should contain every freezed
  /// class detected in the migration run (all files), so cross-references
  /// are rewritten consistently.
  ZorphyRenderer({Set<String>? siblingClassNames})
    : siblingClassNames = siblingClassNames ?? const {};

  /// Renders the replacement source for [model]. Caller guarantees
  /// [FreezedClassModel.isMigratable].
  String render(FreezedClassModel model) {
    final sb = StringBuffer();
    switch (model.dialect) {
      case ModelDialect.freezed:
        if (model.isUnion) {
          _renderUnion(model, sb);
        } else {
          _renderSimple(model, sb);
        }
      case ModelDialect.exchangeableObject:
        _renderExchangeableObject(model, sb);
      case ModelDialect.exchangeableEnum:
        _renderExchangeableEnum(model, sb);
    }
    return sb.toString().trimRight();
  }

  /// Rewrites a field type for the exchangeable dialect: references to
  /// classes being converted in the same run drop the codegen `_` suffix
  /// (`URLRequest_` → `URLRequest`). Non-sibling types pass through.
  String _convertExchangeableType(String type) {
    var result = type;
    for (final name in siblingClassNames) {
      result = result.replaceAllMapped(
        RegExp('(?<!\\w)${name}_(?!\\w)'),
        (m) => name,
      );
    }
    return result;
  }

  /// Rewrites a field type, `$`-prefixing references to migrated classes.
  /// Handles nullability, generics and nested collections
  /// (`List<CartItem>?` → `List<$CartItem>?`).
  String convertType(String type) {
    if (siblingClassNames.isEmpty) return type;
    var result = type;
    for (final name in siblingClassNames) {
      result = result.replaceAllMapped(
        RegExp('(?<![\\\$\w])$name(?![\w])'),
        (m) => '\$$name',
      );
    }
    return result;
  }

  String _annotationFor(
    FreezedClassModel model, {
    List<String>? explicitSubTypes,
  }) {
    final args = <String>[];
    if (model.isLeanEligible && explicitSubTypes == null) {
      args.add('preset: ZorphyPreset.lean');
    }
    if (model.hasFromJson || model.hasToJson) {
      args.add('generateJson: true');
    }
    if (explicitSubTypes != null && explicitSubTypes.isNotEmpty) {
      args.add('explicitSubTypes: [${explicitSubTypes.join(', ')}]');
    }
    return '@Zorphy(${args.join(', ')})';
  }

  String _typeParams(FreezedClassModel model) =>
      model.typeParameters.isEmpty ? '' : '<${model.typeParameters.join(', ')}>';

  void _renderSimple(FreezedClassModel model, StringBuffer sb) {
    final className = '\$${model.name}';

    if (model.docComment != null) sb.writeln(model.docComment);
    sb.writeln(_annotationFor(model));
    sb.writeln('abstract class $className${_typeParams(model)} {');
    for (final field in model.fields) {
      _renderField(field, sb);
    }
    sb.writeln('}');
  }

  void _renderField(FreezedField field, StringBuffer sb) {
    if (field.docComment != null) sb.writeln('  ${field.docComment}');
    final jsonKeys = [...field.jsonKeyAnnotations];
    // freezed @Default(expr) → zorphy's default-value mechanism:
    // @JsonKey(defaultValue: expr) on the getter makes the generated
    // constructor parameter optional with the expression as fallback.
    if (field.defaultExpression != null) {
      final existing = jsonKeys.indexWhere((k) => k.startsWith('@JsonKey('));
      if (existing >= 0) {
        jsonKeys[existing] = jsonKeys[existing].replaceFirst(
          '@JsonKey(',
          '@JsonKey(defaultValue: ${field.defaultExpression}, ',
        );
      } else {
        jsonKeys.add('@JsonKey(defaultValue: ${field.defaultExpression})');
      }
    }
    for (final jsonKey in jsonKeys) {
      sb.writeln('  $jsonKey');
    }
    sb.writeln('  ${convertType(field.type)} get ${field.name};');
  }

  /// Renders an `@ExchangeableObject()` value object as a Zorphy value
  /// entity, matching the zikzak_inappwebview conversion convention
  /// (see PROGRESS.md recipe).
  void _renderExchangeableObject(FreezedClassModel model, StringBuffer sb) {
    if (model.docComment != null) sb.writeln(model.docComment);
    sb
      ..writeln('@Zorphy(')
      ..writeln('  kind: ZorphyKind.valueObject,')
      ..writeln('  generateJson: true,')
      ..writeln('  generateCompareTo: true,')
      ..writeln(')')
      ..writeln('abstract class \$${model.name} {');
    for (final field in model.fields) {
      _renderExchangeableField(field, sb);
    }
    sb.writeln('}');
  }

  void _renderExchangeableField(FreezedField field, StringBuffer sb) {
    final fieldDoc = field.docComment;
    if (fieldDoc != null) {
      for (final line in fieldDoc.split('\n')) {
        sb.writeln('  $line');
      }
    }
    if (field.defaultExpression != null) {
      sb.writeln(
        '  @JsonKey(defaultValue: ${field.defaultExpression})',
      );
    }
    sb.writeln(
      '  ${_convertExchangeableType(field.type)} get ${field.name};',
    );
  }

  /// Renders an `@ExchangeableEnum()` class-based enum as a plain Dart
  /// enum. Member names and declaration order (== the old wire order) are
  /// preserved; doc comments are kept on the members.
  void _renderExchangeableEnum(FreezedClassModel model, StringBuffer sb) {
    if (model.docComment != null) sb.writeln(model.docComment);
    sb.writeln('enum ${model.name} {');
    for (var i = 0; i < model.enumMembers.length; i++) {
      final doc = model.enumMemberDocs.length > i
          ? model.enumMemberDocs[i]
          : null;
      if (doc != null) {
        for (final line in doc.split('\n')) {
          sb.writeln('  $line');
        }
      }
      sb.writeln('  ${model.enumMembers[i]},');
    }
    sb.writeln('}');
  }

  void _renderUnion(FreezedClassModel model, StringBuffer sb) {
    // Sealed base: $$Foo — explicitSubTypes reference the $-prefixed
    // abstract classes (zorphy convention, see README "Sealed Abstract
    // Classes").
    final baseJson = model.hasFromJson || model.hasToJson;
    if (model.docComment != null) sb.writeln(model.docComment);
    sb.writeln(
      _annotationFor(
        model,
        explicitSubTypes: model.variants
            .map((v) => '\$${v.className}')
            .toList(),
      ),
    );
    sb.writeln(
      'abstract class \$${'\$'}${model.name}${_typeParams(model)} {',
    );
    sb.writeln('}');

    for (final variant in model.variants) {
      // Variants of a sealed base keep the standard preset and mirror the
      // base's JSON flag: they participate in the polymorphic
      // discriminator machinery via the base.
      final variantAnnotation = baseJson
          ? '@Zorphy(generateJson: true)'
          : '@Zorphy()';
      sb
        ..writeln()
        ..writeln(variantAnnotation)
        ..writeln(
          'abstract class \$${variant.className}${_typeParams(model)} '
          'implements \$${'\$'}${model.name}${_typeParams(model)} {',
        );
      for (final field in variant.fields) {
        _renderField(field, sb);
      }
      sb.writeln('}');
    }
  }
}
