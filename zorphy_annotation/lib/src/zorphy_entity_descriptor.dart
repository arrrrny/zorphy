import 'archetype_bases.dart';
import 'boundary.dart';
import 'patch.dart';
import 'query/field.dart';

/// A reflection-free, generic runtime seam over a generated `@ZorphyEntity`.
///
/// Dart AOT has no `dart:mirrors`, so a generic container (`ZfaStore`,
/// `ZfaDocument<T>`) cannot discover an entity's principal key, fields, diff,
/// patch or wire codec from the type alone. The code generator emits one
/// `static const <Entity>descriptor = _<Entity>Descriptor();` on every
/// `@ZorphyEntity`, and a generic algorithm operates purely on
/// [ZorphyEntityDescriptor<T>] — no `runtimeType` switch, no reflective field
/// lookup, valid under AOT (issue #251 / ZRP-003).
///
/// The descriptor is the first generic seam over two surfaces that are static
/// on generated types: `fromWire` (a static on the entity, returning a
/// [ZorphyBoundaryResult]) and `diff` (a static on `<Entity>Patch`). The
/// emitted `_<Entity>Descriptor` closes over both, so a caller holding only the
/// descriptor can round-trip an entity it never names concretely.
///
/// [TValue] on the field accessors is `Object?`: a descriptor is heterogeneous
/// by construction (one entity carries fields of many types), so the principal
/// key and every field are widened to [Object] on read. The generated
/// `_<Entity>Descriptor` supplies the typed extractor closures.
abstract interface class ZorphyEntityDescriptor<T extends ZorphyEntityBase> {
  /// The generated entity's clean type name, e.g. `'Product'`.
  String get typeName;

  /// The field the entity's identity is read from — the `principalKey` the
  /// `@ZorphyEntity` annotation named (e.g. `#id`).
  Field<T, Object?> get principalKeyField;

  /// Every field visible on [T], in declaration order (own fields first, then
  /// each ancestor's), each widened to [Object] on read.
  List<Field<T, Object?>> get fields;

  /// The patch that turns [previous] into [next] — the generic name for the
  /// generated `<Entity>Patch.diff`.
  ZorphyPatch<T> diff(T previous, T next);

  /// Returns [entity] with [patch] applied — the generic seam over the
  /// generated patch's `apply`.
  T applyPatch(T entity, ZorphyPatch<T> patch);

  /// The wire form of [entity] — the generic seam over the generated
  /// `toWire`.
  Map<String, Object?> toWire(T entity);

  /// Decodes [raw] at the trust boundary — the generic seam over the generated
  /// static `fromWire`, which never leaks a raw [TypeError]/[CastError].
  ZorphyBoundaryResult<T> fromWire(Map<String, Object?> raw);

  /// The principal-key value of [entity], read through [principalKeyField].
  Object principalKeyOf(T entity);

  /// The field addressed by [jsonPointer] (e.g. `'/name'` or `'name'`), or
  /// `null` when no visible field carries that name.
  Field<T, Object?>? fieldByPath(String jsonPointer);

  /// The exact set of JSON pointers BOTH [a] and [b] change — the conflict set
  /// a three-way sync surfaces.
  ///
  /// The changed top-level fields are the patches' wire keys, so the conflict
  /// set is the intersection rendered as JSON pointers — reflection-free and
  /// identical for every entity.
  Set<String> conflictingPaths(ZorphyPatch<T> a, ZorphyPatch<T> b);

  /// Applies [next] over [base] — the three-way-merge name for composition,
  /// delegating to [ZorphyPatch.compose] whose left-to-right law
  /// `apply(x) == next.apply(apply(x))` every generated patch satisfies.
  ZorphyPatch<T> composePatches(ZorphyPatch<T> base, ZorphyPatch<T> next);
}
