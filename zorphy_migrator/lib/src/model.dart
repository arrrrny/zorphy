/// Data model for a detected freezed class, before conversion.
library;

/// A single field on a freezed data class (from a factory parameter).
class FreezedField {
  final String name;
  final String type;
  final bool isRequired;
  final String? defaultExpression;
  final List<String> jsonKeyAnnotations;

  const FreezedField({
    required this.name,
    required this.type,
    required this.isRequired,
    this.defaultExpression,
    this.jsonKeyAnnotations = const [],
  });
}

/// One union variant: `factory Foo.ok(T v) = Ok;`
class UnionVariant {
  /// Variant class name (the redirect target), e.g. `Ok`.
  final String className;

  /// Factory constructor name on the base, e.g. `ok`.
  final String factoryName;

  final List<FreezedField> fields;

  const UnionVariant({
    required this.className,
    required this.factoryName,
    required this.fields,
  });
}

/// Something the migrator cannot convert; always surfaced, never dropped.
class ManualItem {
  final String filePath;
  final int line;
  final String construct;
  final String reason;

  const ManualItem({
    required this.filePath,
    required this.line,
    required this.construct,
    required this.reason,
  });
}

/// A detected freezed class with everything needed to rewrite it.
class FreezedClassModel {
  /// Class name without the freezed mixin, e.g. `User`.
  final String name;

  /// Absolute path of the file the class was detected in.
  final String filePath;

  final List<String> typeParameters;
  final List<FreezedField> fields;
  final List<UnionVariant> variants;
  final bool hasFromJson;
  final bool hasToJson;
  final bool isUnfreezed;
  final List<ManualItem> manualItems;

  /// Character offsets of the full class declaration in the source.
  final int spanStart;
  final int spanEnd;

  /// Documentation comment source (with `///` markers) directly attached
  /// to the class, preserved on the generated `$` class.
  final String? docComment;

  const FreezedClassModel({
    required this.name,
    required this.filePath,
    required this.typeParameters,
    required this.fields,
    required this.variants,
    required this.hasFromJson,
    required this.hasToJson,
    required this.isUnfreezed,
    required this.manualItems,
    required this.spanStart,
    required this.spanEnd,
    this.docComment,
  });

  bool get isUnion => variants.isNotEmpty;

  /// A class can be fully auto-migrated only when it has no manual items
  /// and is not @unfreezed.
  bool get isMigratable => !isUnfreezed && manualItems.isEmpty;

  /// True when the class provably uses only lean-preset features:
  /// no union, no defaults, plain fields only.
  bool get isLeanEligible =>
      !isUnion && fields.every((f) => f.defaultExpression == null);
}
