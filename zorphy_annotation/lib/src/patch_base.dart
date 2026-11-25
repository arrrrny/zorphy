import 'patch.dart';

/// The base every generated `<Name>Patch` extends (ISSUE-007).
///
/// It implements both patch surfaces: the legacy [Patch] entry point the
/// original `patchWith` resolves a carried field through, and the v3
/// [ZorphyPatch] algebra (`isEmpty` / `apply` / `compose` / `invert` /
/// `toWire`) the generated class fills in. Implementing [ZorphyPatch] here is
/// what lets a generated patch stand in for the `SubPatch` bound of
/// [PatchNested] — a nested field carries its sub-entity's own generated patch,
/// so that patch has to BE a [ZorphyPatch] of the sub-entity (ISSUE-008).
abstract class PatchBase<TEntity, TEnum extends Enum>
    implements Patch<TEntity>, ZorphyPatch<TEntity> {
  /// Creates a patch holding [patchMap], or a fresh mutable map when it is
  /// omitted.
  ///
  /// The no-argument form is what the fluent `with*` builders mutate, so it
  /// allocates per instance. A patch that is meant to be constant — the empty
  /// patch, which must be the O(1) neutral element of `compose` — is built
  /// through [PatchBase.empty] instead.
  PatchBase([Map<TEnum, dynamic>? patchMap])
    : patchMap = patchMap ?? <TEnum, dynamic>{};

  /// Creates a patch over a shared `const` empty map.
  ///
  /// Const-constructible and allocation-free: the map is the canonical empty
  /// one, so `isEmpty` is `true` for the whole life of the patch and no
  /// mutation is possible. Generated patches expose it as their `.empty`
  /// constructor.
  const PatchBase.empty() : patchMap = const <Never, Never>{};

  /// The field-keyed changes this patch carries.
  final Map<TEnum, dynamic> patchMap;

  /// Whether this patch carries at least one change.
  ///
  /// [ZorphyPatch] gives this a body, but `implements` does not inherit it, so
  /// the concrete generated patch would otherwise have to restate a one-line
  /// negation of [isEmpty].
  @override
  bool get isNotEmpty => !isEmpty;

  /// The JSON pointers this patch changes, e.g. `{'/price', '/title'}`.
  ///
  /// Each touched field contributes `/<field>`. A nested field carries a
  /// [PatchNested] whose own sub-patch is a [PatchBase]; its leaf paths are
  /// expanded under the field, so `/address/street` and `/address/city` are
  /// distinct paths and two edits under one object conflict only on the leaf
  /// they share. A whole-value transition (a null on either side, or a fluent
  /// `with*` builder that wrote a raw value) is the field path itself.
  Set<String> get changedPaths {
    final paths = <String>{};
    patchMap.forEach((key, value) {
      final name = wireNameFor(key);
      final nested = value is PatchNested ? value.patch : null;
      if (nested is PatchBase) {
        final child = nested.changedPaths;
        if (child.isEmpty) {
          paths.add('/$name');
        } else {
          for (final path in child) {
            paths.add('/$name$path');
          }
        }
      } else {
        paths.add('/$name');
      }
    });
    return paths;
  }

  /// The wire/field name a patch key addresses, e.g. `price` for `Price$.price`.
  ///
  /// Generated patches override this with the enum-member → original-field-name
  /// mapping: reserved names are escaped in the field enum (`name` becomes
  /// `name_`), but [toJson]/`toWire()` write the original name, so a pointer
  /// built from `key.name` alone would not address the wire field. The default
  /// keeps hand-written patches working when a key is not escaped.
  String wireNameFor(TEnum key) => key.name;

  /// The exact set of paths BOTH this patch and [other] change — the conflict
  /// set a three-way sync surfaces as `AppFailure.conflict`.
  ///
  /// Disjoint edits return an empty set; an overlapping scalar or a concurrent
  /// atomic list replacement returns the shared pointer. A whole-value
  /// replacement also conflicts with any edit BENEATH it at a JSON-pointer
  /// token boundary (`/previousAddress` conflicts with
  /// `/previousAddress/street`), while sibling leaves under one object
  /// (`/address/street`, `/address/city`) stay disjoint.
  Set<String> conflictingPaths(PatchBase<TEntity, TEnum> other) {
    final mine = changedPaths;
    final theirs = other.changedPaths;
    final conflicts = <String>{};
    for (final a in mine) {
      for (final b in theirs) {
        final path = _conflictPath(a, b);
        if (path != null) conflicts.add(path);
      }
    }
    return conflicts;
  }

  /// Applies [next] over this patch — the three-way-merge name for [compose].
  ///
  /// This is an ALIAS of [compose] with identical left-to-right semantics
  /// (`apply(x) == next.apply(apply(x))`); it exists so three-way sync reads
  /// naturally without leaving two composition behaviours to tell apart. It
  /// returns the [ZorphyPatch] interface; chain further with [compose], which
  /// is declared on that interface.
  ZorphyPatch<TEntity> composePatches(covariant ZorphyPatch<TEntity> next) =>
      compose(next);

  Map<TEnum, dynamic> toPatch() => Map.from(patchMap);

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    patchMap.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.name;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if ((value as dynamic).toJsonLean != null)
        return (value as dynamic).toJsonLean();
    } catch (_) {}
    try {
      if ((value as dynamic).toJson != null) return (value as dynamic).toJson();
    } catch (_) {}
    return value.toString();
  }
}

/// The pointer both paths fight over, or `null` when they are disjoint.
///
/// Comparison is at JSON-pointer token boundaries: `/a` and `/a/b` conflict
/// (a replacement of `/a` discards the edit beneath it), but `/a/b` and
/// `/a/c` do not. When one path is an ancestor of the other, the ancestor is
/// returned — it names the whole value whose replacement loses the edit.
String? _conflictPath(String a, String b) {
  if (a == b) return a;
  if (a.startsWith('$b/')) return b;
  if (b.startsWith('$a/')) return a;
  return null;
}
