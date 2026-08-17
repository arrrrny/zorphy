/// Data model for a detected freezed class, before conversion.
library;

/// A single field on a freezed data class (from a factory parameter).
class FreezedField {
  final String name;
  final String type;
  final bool isRequired;
  final String? defaultExpression;
  final List<String> jsonKeyAnnotations;

  /// Doc-comment source (with `///` markers) attached to the field /
  /// parameter, preserved on the generated getter.
  final String? docComment;

  const FreezedField({
    required this.name,
    required this.type,
    required this.isRequired,
    this.defaultExpression,
    this.jsonKeyAnnotations = const [],
    this.docComment,
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

/// The input dialect a detected model came from. The migrator converts
/// freezed_annotation classes and, for codegen-heavy fork packages that do
/// not use Freezed at all (e.g. flutter_inappwebview's
/// `@ExchangeableObject` / `@ExchangeableEnum`), the equivalent custom
/// codegen annotations — same destination (Zorphy entities), different
/// source syntax.
enum ModelDialect {
  /// `@freezed` / `@unfreezed` classes from `package:freezed_annotation`.
  freezed,

  /// `@ExchangeableObject()` value-object classes (custom build_runner
  /// codegen, e.g. zikzak_inappwebview / flutter_inappwebview forks).
  exchangeableObject,

  /// `@ExchangeableEnum()` class-based enums (a class with a `_value`
  /// field and `static const` members).
  exchangeableEnum,
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

  /// Which source dialect produced this model.
  final ModelDialect dialect;

  /// For [ModelDialect.exchangeableEnum]: the `static const` member names
  /// in declaration order. Empty for other dialects.
  final List<String> enumMembers;

  /// For [ModelDialect.exchangeableEnum]: doc-comment source per member
  /// (aligned with [enumMembers]), or `null` where the member had none.
  final List<String?> enumMemberDocs;

  /// Non-blocking items reported alongside a converted model: the model
  /// still migrates, but the reader is told what needs hand attention
  /// afterwards (e.g. an enum whose wire values do not map onto a plain
  /// enum's `.index`/name — the conversion is safe, the consumer glue is
  /// not). Unlike [manualItems], these do NOT make the model unmigratable.
  final List<ManualItem> informationalItems;

  /// For [ModelDialect.exchangeableObject]: source snippets of static
  /// methods returning the class's own type (e.g. `static Foo_ bar(...)`
  /// convenience factories). The zorphy generator carries these onto the
  /// generated concrete class, so they are preserved on the migrated `$`
  /// class instead of being dropped. Empty for other dialects.
  final List<String> staticMethods;

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
    this.dialect = ModelDialect.freezed,
    this.enumMembers = const [],
    this.enumMemberDocs = const [],
    this.informationalItems = const [],
    this.staticMethods = const [],
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
