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
    if (model.isUnion) {
      _renderUnion(model, sb);
    } else {
      _renderSimple(model, sb);
    }
    return sb.toString().trimRight();
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
