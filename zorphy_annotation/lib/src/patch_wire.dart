/// Wire codecs for the patch algebra (ISSUE-017, #192).
///
/// A patch crosses a process boundary — a VM Service link, a platform
/// channel, a WebView bridge — so its wire form is decoded at a TRUST
/// BOUNDARY. Untrusted input must never leak a raw `TypeError` or `CastError`
/// to the caller: every read here is an `is` test on the `Object?` the wire
/// handed over, and a value of the wrong shape becomes a [FieldViolation]
/// rather than a thrown cast, exactly the contract
/// `BoundaryCodecEmitter` keeps for entities (ISSUE-013).
///
/// ## The envelope
///
/// A polymorphic patch is carried as an envelope so a receiver knows which
/// patch class to build before it reads a single field:
///
/// ```json
/// {
///   "entityType": "Notification",
///   "patchKind": "shared",
///   "principalKey": "notif-42",
///   "ops": { "readAt": "2026-11-22T10:00:00.000Z" }
/// }
/// ```
///
/// `ops` is the patch's own [ZorphyPatch.toWire] map — unchanged fields are
/// absent from it, which is what keeps an IPC payload small. `principalKey` is
/// entity-level transport metadata (a patch names changes, not a row), so it
/// rides along without contributing to the decode.
///
/// ## A decoded delta is all-or-nothing
///
/// A list or map delta is either decoded in full or not at all. A partially
/// decoded delta would silently drop the operations that failed to parse, and
/// a patch that quietly loses an operation is data loss nobody sees — so a
/// single bad step fails the whole field, and [ListPatchDelta] / [MapPatchDelta]
/// are only built once every step has been read.
library;

import 'boundary.dart';
import 'patch.dart';

/// The field-level decode primitives a generated patch `fromWire` calls.
///
/// Every member is total: a value of the wrong shape appends a
/// [FieldViolation] and answers `null`, never a thrown cast.
abstract final class ZorphyPatchWire {
  /// The envelope key naming the entity (or hierarchy root) type.
  static const String entityTypeKey = 'entityType';

  /// The envelope key naming which patch class the ops belong to.
  static const String patchKindKey = 'patchKind';

  /// The envelope key carrying the patch's own `toWire()` map.
  static const String opsKey = 'ops';

  /// The envelope key carrying the principal key of the row being patched.
  ///
  /// Transport metadata: it names WHICH row a patch is for, and never
  /// contributes to the decoded patch.
  static const String principalKeyKey = 'principalKey';

  /// The names an envelope reserves: a generated patch field may not use one.
  ///
  /// A bare `toWire()` map keys each field by its own name, so a field called
  /// `ops` or `patchKind` would be mistaken for envelope metadata by [opsOf]
  /// and [opsPathOf] (#215). The emitters refuse such fields at generation
  /// time rather than shipping a wire format with a silent ambiguity.
  static const Set<String> reservedEnvelopeKeys = <String>{
    entityTypeKey,
    patchKindKey,
    opsKey,
    principalKeyKey,
  };

  /// The `patchKind` a hierarchy's shared patch answers to.
  static const String sharedPatchKind = 'shared';

  /// A short, bounded description of [value] for a violation's `actual`.
  static String describe(Object? value) {
    if (value == null) return 'null';
    final text = value.toString();
    final clipped = text.length > 60 ? '${text.substring(0, 60)}…' : text;
    return '${value.runtimeType} ("$clipped")';
  }

  /// [value] as a [T], or a violation at [path].
  ///
  /// A `null` is a legitimate value only when [nullable]; a non-nullable field
  /// receiving `null` is a violation, so a corrupt payload cannot slip a
  /// `null` past a `T`-typed field.
  ///
  /// A nullable field's legitimate `null` and a failed read are both `null` in
  /// the value domain, so a caller that must tell them apart compares
  /// [violations] before and after the read (the emitted patch code does
  /// exactly that) rather than testing the answer.
  static T? as<T>(
    Object? value,
    String path,
    List<FieldViolation> violations, {
    bool nullable = false,
  }) {
    if (value == null && !nullable) {
      violations.add(
        FieldViolation(path: path, expected: '$T', actual: 'null'),
      );
      return null;
    }
    if (value is T) return value;
    if (value == null) return null;
    violations.add(
      FieldViolation(path: path, expected: '$T', actual: describe(value)),
    );
    return null;
  }

  /// [value] as a [num], preserving an integer rather than rounding it.
  ///
  /// A declared `num` field may carry a large `int` that a `double` cannot
  /// represent exactly (`9007199254740993` on the VM). Only a field declared
  /// `double` converts an integer with [asDouble].
  static num? asNum(
    Object? value,
    String path,
    List<FieldViolation> violations,
  ) {
    if (value is num) return value;
    violations.add(
      FieldViolation(path: path, expected: 'num', actual: describe(value)),
    );
    return null;
  }

  /// [value] as a `double`, accepting a JSON integer (`1` is a legal `1.0`).
  static double? asDouble(
    Object? value,
    String path,
    List<FieldViolation> violations,
  ) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    violations.add(
      FieldViolation(path: path, expected: 'double', actual: describe(value)),
    );
    return null;
  }

  /// [value] as a [DateTime], accepting an ISO-8601 string.
  ///
  /// A `DateTime` reaches the wire as a string ([ZorphyPatch.toWire] leaves a
  /// raw `DateTime` untouched for a scalar field, so both spellings are legal).
  static DateTime? asDateTime(
    Object? value,
    String path,
    List<FieldViolation> violations,
  ) {
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      // DateTime.tryParse NORMALIZES out-of-range components: 2020-01-42
      // becomes 2020-02-11, 25:00 becomes 01:00 the next day. A corrupt wire
      // value must be a violation, never a silently different instant (#215).
      if (parsed != null && _hasValidIsoCalendar(value)) return parsed;
    }
    violations.add(
      FieldViolation(
        path: path,
        expected: 'DateTime (ISO-8601 String)',
        actual: describe(value),
      ),
    );
    return null;
  }

  /// [value] as one of [values], matched by NAME rather than by index.
  ///
  /// An index would silently re-point every wire message the moment a value
  /// is inserted into the enum, so a name is the only stable spelling. A
  /// payload decoded in-process (no JSON hop) still carries the enum value
  /// itself, so an instance of [E] is accepted as-is.
  static E? enumByName<E extends Enum>(
    List<E> values,
    Object? value,
    String path,
    List<FieldViolation> violations,
  ) {
    if (value is E && values.contains(value)) return value;
    if (value is String) {
      for (final candidate in values) {
        if (candidate.name == value) return candidate;
      }
    }
    violations.add(
      FieldViolation(
        path: path,
        expected: 'one of: ${values.map((e) => e.name).join(', ')}',
        actual: describe(value),
      ),
    );
    return null;
  }

  /// [value] as a `Map<String, Object?>`.
  ///
  /// A map with non-String keys is refused rather than coerced: `'$key'` would
  /// invent string keys and hide the corruption.
  static Map<String, Object?>? asObject(
    Object? value,
    String path,
    List<FieldViolation> violations,
  ) {
    if (value is Map<String, Object?>) return value;
    violations.add(
      FieldViolation(
        path: path,
        expected: 'Map<String, Object?>',
        actual: describe(value),
      ),
    );
    return null;
  }

  /// Re-paths [violations] under [path], for a nested decode's result.
  static List<FieldViolation> prefix(
    List<FieldViolation> violations,
    String path,
  ) => violations
      .map(
        (violation) => FieldViolation(
          path: '$path${violation.path}',
          expected: violation.expected,
          actual: violation.actual,
        ),
      )
      .toList();

  /// Escapes [key] as one RFC 6901 JSON Pointer token.
  ///
  /// Without this, a map key `a/b` appended to `/scores` reads as two segments
  /// and a key `~1` collides with `a/b` (#215).
  static String pointerToken(Object? key) =>
      key.toString().replaceAll('~', '~0').replaceAll('/', '~1');

  /// Declares that [key] must be present in [map], reporting a violation at
  /// `<path>/<key>` when it is absent.
  ///
  /// A missing member and an explicit `null` are different things: a nullable
  /// field's clear is `{'value': null}` and must decode, while `{'op': 'set'}`
  /// with no `value` is a corrupt descriptor that must fail (#215).
  static bool requireMember(
    Map<String, Object?> map,
    String key,
    String path,
    List<FieldViolation> violations,
  ) {
    if (map.containsKey(key)) return true;
    violations.add(
      FieldViolation(
        path: '$path/$key',
        expected: 'member $key',
        actual: 'missing',
      ),
    );
    return false;
  }

  /// The `patchKind` [raw] carries, or `null` when it carries no envelope.
  static String? patchKindOf(Map<String, Object?> raw) {
    final kind = raw[patchKindKey];
    return kind is String ? kind : null;
  }

  /// The `entityType` [raw] carries, or `null` when it carries no envelope.
  static String? entityTypeOf(Map<String, Object?> raw) {
    final type = raw[entityTypeKey];
    return type is String ? type : null;
  }

  /// The `principalKey` [raw] carries, if any.
  static Object? principalKeyOf(Map<String, Object?> raw) =>
      raw[principalKeyKey];

  /// The patch ops [raw] carries, whether [raw] is an envelope or a bare
  /// `toWire()` map.
  ///
  /// A bare map is what a transport that already knows the patch kind carries
  /// (`p.toWire()`), so requiring an envelope everywhere would force every
  /// caller through a wrapper it does not need.
  static Map<String, Object?>? opsOf(
    Map<String, Object?> raw,
    String path,
    List<FieldViolation> violations,
  ) {
    if (!raw.containsKey(patchKindKey) && !raw.containsKey(opsKey)) {
      return raw;
    }
    final ops = raw[opsKey];
    if (ops == null && !raw.containsKey(opsKey)) {
      violations.add(
        FieldViolation(
          path: '$path/$opsKey',
          expected: 'Map<String, Object?>',
          actual: describe(null),
        ),
      );
      return null;
    }
    return asObject(ops, '$path/$opsKey', violations);
  }

  /// The path prefix a field read sits under: `/ops` for an envelope, empty
  /// for a bare `toWire()` map.
  ///
  /// A violation must name the pointer a caller can see in the payload it
  /// sent, so a field read off an envelope's `ops` reports `/ops/<field>`
  /// rather than a path that only matches the bare form.
  static String opsPathOf(Map<String, Object?> raw) =>
      raw.containsKey(patchKindKey) || raw.containsKey(opsKey)
      ? '/$opsKey'
      : '';

  /// One field's value, unwrapping the explicit-set spelling a peer may send
  /// in place of the bare value (`toWire()` writes the bare value, so both are
  /// accepted).
  ///
  /// The explicit set is a [PatchWireSet], never a map with an `op` key: a map
  /// field is allowed to contain a literal `op` entry, and reading that as a
  /// descriptor silently lost the field (#215).
  static Object? fieldValue(
    Object? value,
    String path,
    List<FieldViolation> violations,
  ) => value is PatchWireSet ? value.value : value;

  /// The delta [raw] carries for a list field, or `null` when it could not be
  /// decoded in full.
  ///
  /// [decodeElement] decodes one element of the list's `E`; the emitted call
  /// site knows that type, and the delta's ops must carry it.
  static ListPatchDelta<E>? listDelta<E>(
    Object? raw,
    String path,
    List<FieldViolation> violations,
    E? Function(Object? value, String path, List<FieldViolation> violations)
    decodeElement,
  ) {
    final before = violations.length;

    // A raw list (a fluent `with*` builder wrote the collection itself)
    // becomes one replaceAll: applying it produces the same list.
    if (raw is List) {
      final items = <E>[];
      for (var i = 0; i < raw.length; i++) {
        final elementBefore = violations.length;
        final decoded = decodeElement(raw[i], '$path/$i', violations);
        // A clean read of a nullable element answers null too. Track SUCCESS
        // with the violation count, never the decoded value (#215).
        if (violations.length == elementBefore) items.add(decoded as E);
      }
      if (violations.length != before) return null;
      return ListPatchDelta<E>(<ListPatchOp<E>>[
        ListPatchOp<E>.replaceAll(items),
      ]);
    }

    final map = asObject(raw, path, violations);
    if (map == null) return null;
    final opsRaw = map[opsKey];
    if (opsRaw is! List) {
      violations.add(
        FieldViolation(
          path: '$path/$opsKey',
          expected: 'List<Object?>',
          actual: describe(opsRaw),
        ),
      );
      return null;
    }

    final ops = <ListPatchOp<E>>[];
    // replaceAll fixes the list length for every target; append/removeAt move
    // it, updateAt leaves it. While the length is known, an index that cannot
    // ever be valid is a decode violation — applying it would throw RangeError.
    int? knownLength;
    for (var i = 0; i < opsRaw.length; i++) {
      final opPath = '$path/$opsKey/$i';
      final op = asObject(opsRaw[i], opPath, violations);
      if (op == null) continue;
      switch (op['op']) {
        case 'replaceAll':
          if (!requireMember(op, 'items', opPath, violations)) continue;
          final itemsRaw = op['items'];
          if (itemsRaw is! List) {
            violations.add(
              FieldViolation(
                path: '$opPath/items',
                expected: 'List<Object?>',
                actual: describe(itemsRaw),
              ),
            );
            continue;
          }
          final items = <E>[];
          for (var j = 0; j < itemsRaw.length; j++) {
            final elementBefore = violations.length;
            final decoded = decodeElement(
              itemsRaw[j],
              '$opPath/items/$j',
              violations,
            );
            if (violations.length == elementBefore) items.add(decoded as E);
          }
          ops.add(ListPatchOp<E>.replaceAll(items));
          knownLength = items.length;
        case 'append':
          if (!requireMember(op, 'item', opPath, violations)) continue;
          final elementBefore = violations.length;
          final decoded = decodeElement(op['item'], '$opPath/item', violations);
          if (violations.length != elementBefore) continue;
          ops.add(ListPatchOp<E>.append(decoded as E));
          if (knownLength != null) knownLength = knownLength + 1;
        case 'removeAt':
          final index = _listIndex(op, opPath, knownLength, violations);
          if (index == null) continue;
          ops.add(ListPatchOp<E>.removeAt(index));
          if (knownLength != null) knownLength = knownLength - 1;
        case 'updateAt':
          final index = _listIndex(op, opPath, knownLength, violations);
          if (!requireMember(op, 'item', opPath, violations)) continue;
          final elementBefore = violations.length;
          final decoded = decodeElement(op['item'], '$opPath/item', violations);
          if (violations.length != elementBefore) continue;
          if (index == null) continue;
          ops.add(ListPatchOp<E>.updateAt(index, decoded as E));
        default:
          // The OP itself is the offending value, so the pointer the caller
          // must look at is the step, not a member inside it.
          violations.add(
            FieldViolation(
              path: opPath,
              expected: "one of: replaceAll, append, removeAt, updateAt",
              actual: describe(op['op']),
            ),
          );
      }
    }

    // All-or-nothing: a partial delta would silently drop the steps that
    // failed, and a patch that loses an operation is data loss nobody sees.
    if (violations.length != before) return null;
    return ListPatchDelta<E>(ops);
  }

  /// The atomic list [raw] carries for a list field, or `null` when it could
  /// not be decoded in full (zorphy#248).
  ///
  /// A list field is patched by whole-value replacement, so its wire form is a
  /// bare JSON array rather than a `{'ops': [...]}` delta. [decodeElement]
  /// decodes one element of the list's `E`; the emitted call site knows that
  /// type. All-or-nothing, like [listDelta]: a single bad element nullifies the
  /// whole read instead of shipping a silently short list.
  static List<E>? listValue<E>(
    Object? raw,
    String path,
    List<FieldViolation> violations,
    E? Function(Object? value, String path, List<FieldViolation> violations)
    decodeElement,
  ) {
    if (raw is! List) {
      violations.add(
        FieldViolation(path: path, expected: 'List<$E>', actual: describe(raw)),
      );
      return null;
    }
    final before = violations.length;
    final items = <E>[];
    for (var i = 0; i < raw.length; i++) {
      final elementBefore = violations.length;
      final decoded = decodeElement(raw[i], '$path/$i', violations);
      // A clean read of a nullable element answers null too. Track SUCCESS
      // with the violation count, never the decoded value (#215).
      if (violations.length == elementBefore) items.add(decoded as E);
    }
    if (violations.length != before) return null;
    return items;
  }

  /// The atomic map [raw] carries for a map field, or `null` when it could not
  /// be decoded in full.
  static Map<K, V>? mapValue<K, V>(
    Object? raw,
    String path,
    List<FieldViolation> violations, {
    required K? Function(
      Object? value,
      String path,
      List<FieldViolation> violations,
    )
    decodeKey,
    required V? Function(
      Object? value,
      String path,
      List<FieldViolation> violations,
    )
    decodeValue,
  }) {
    if (raw is! Map) {
      violations.add(
        FieldViolation(
          path: path,
          expected: 'Map<$K, $V>',
          actual: describe(raw),
        ),
      );
      return null;
    }
    final before = violations.length;
    final out = <K, V>{};
    for (final entry in raw.entries) {
      final entryPath = '$path/${pointerToken(entry.key)}';
      final key = decodeKey(entry.key, entryPath, violations);
      final value = decodeValue(entry.value, entryPath, violations);
      if (violations.length == before) {
        out[key as K] = value as V;
      }
    }
    if (violations.length != before) return null;
    return out;
  }

  /// Reads an `index` member for a positional list step, refusing a negative
  /// index and an index that the tracked length proves out of range (#215).
  static int? _listIndex(
    Map<String, Object?> op,
    String opPath,
    int? knownLength,
    List<FieldViolation> violations,
  ) {
    if (!requireMember(op, 'index', opPath, violations)) return null;
    final index = as<int>(op['index'], '$opPath/index', violations);
    if (index == null) return null;
    if (index < 0 || (knownLength != null && index >= knownLength)) {
      violations.add(
        FieldViolation(
          path: '$opPath/index',
          expected: knownLength == null
              ? 'non-negative int'
              : 'int in 0..${knownLength - 1}',
          actual: describe(index),
        ),
      );
      return null;
    }
    return index;
  }

  /// The delta [raw] carries for a map field, or `null` when it could not be
  /// decoded in full.
  ///
  /// A MAP is a replacement (every field key is a literal key); a LIST is an
  /// ordered step sequence — `MapPatchDelta.toWire()` emits that list, so a
  /// literal map key named `ops` can no longer be mistaken for a delta (#215).
  ///
  /// [decodeKey] and [decodeValue] decode one `K` and one `V`; the emitted call
  /// site knows both types statically, so no reflection is needed here — a
  /// type variable carries no static members to read, and `String`-keyed JSON
  /// means an int- or enum-keyed map must be re-read by its wire spelling at
  /// the one place that knows what that spelling is.
  static MapPatchDelta<K, V>? mapDelta<K, V>(
    Object? raw,
    String path,
    List<FieldViolation> violations, {
    required K? Function(
      Object? value,
      String path,
      List<FieldViolation> violations,
    )
    decodeKey,
    required V? Function(
      Object? value,
      String path,
      List<FieldViolation> violations,
    )
    decodeValue,
  }) {
    final before = violations.length;

    if (raw is Map) {
      final entries = <K, V>{};
      for (final entry in raw.entries) {
        final entryPath = '$path/${pointerToken(entry.key)}';
        final entryBefore = violations.length;
        final key = decodeKey(entry.key, entryPath, violations);
        final value = decodeValue(entry.value, entryPath, violations);
        if (violations.length == entryBefore) {
          entries[key as K] = value as V;
        }
      }
      if (violations.length != before) return null;
      return MapPatchDelta<K, V>(<MapPatchOp<K, V>>[
        MapPatchOp<K, V>.replaceAll(entries),
      ]);
    }

    if (raw is! List) {
      asObject(raw, path, violations);
      return null;
    }
    final opsRaw = raw;

    final ops = <MapPatchOp<K, V>>[];
    for (var i = 0; i < opsRaw.length; i++) {
      final opPath = '$path/$i';
      final op = asObject(opsRaw[i], opPath, violations);
      if (op == null) continue;
      switch (op['op']) {
        case 'replaceAll':
          if (!requireMember(op, 'entries', opPath, violations)) continue;
          final entriesRaw = op['entries'];
          if (entriesRaw is! Map) {
            violations.add(
              FieldViolation(
                path: '$opPath/entries',
                expected: 'Map<Object?, Object?>',
                actual: describe(entriesRaw),
              ),
            );
            continue;
          }
          final entries = <K, V>{};
          for (final entry in entriesRaw.entries) {
            final entryPath = '$opPath/entries/${pointerToken(entry.key)}';
            final entryBefore = violations.length;
            final key = decodeKey(entry.key, entryPath, violations);
            final value = decodeValue(entry.value, entryPath, violations);
            if (violations.length == entryBefore) {
              entries[key as K] = value as V;
            }
          }
          ops.add(MapPatchOp<K, V>.replaceAll(entries));
        case 'put':
          if (!requireMember(op, 'key', opPath, violations) ||
              !requireMember(op, 'value', opPath, violations)) {
            continue;
          }
          final keyBefore = violations.length;
          final key = decodeKey(op['key'], '$opPath/key', violations);
          final valueBefore = violations.length;
          final value = decodeValue(op['value'], '$opPath/value', violations);
          if (violations.length == keyBefore &&
              violations.length == valueBefore) {
            // A nullable V legitimately decodes to null; success is the
            // violation count, not the value (#215).
            ops.add(MapPatchOp<K, V>.put(key as K, value as V));
          }
        case 'remove':
          if (!requireMember(op, 'key', opPath, violations)) continue;
          final keyBefore = violations.length;
          final key = decodeKey(op['key'], '$opPath/key', violations);
          if (violations.length == keyBefore && key != null) {
            ops.add(MapPatchOp<K, V>.remove(key));
          }
        default:
          violations.add(
            FieldViolation(
              path: opPath,
              expected: 'one of: replaceAll, put, remove',
              actual: describe(op['op']),
            ),
          );
      }
    }

    if (violations.length != before) return null;
    return MapPatchDelta<K, V>(ops);
  }

  /// A `String` map key — the JSON spelling every key arrives as.
  ///
  /// Shipped as a named member so an emitted `Map<String, V>` field passes a
  /// tear-off instead of a closure.
  static String? stringKey(
    Object? value,
    String path,
    List<FieldViolation> violations,
  ) => as<String>(value, path, violations);
}

/// The unambiguous spelling of an explicit field set on the wire.
///
/// A bare value (what `toWire()` emits) and a [PatchWireSet] both decode, but
/// a literal `Map` that happens to contain an `op` key is ALWAYS a literal map
/// — it can no longer be misread as an operation descriptor (#215).
final class PatchWireSet {
  const PatchWireSet(this.value);

  /// The value to set — `null` is a valid clear for a nullable field.
  final Object? value;
}

/// A whole-value replacement for a nested field, as opposed to a
/// [PatchNested]-style edit of the existing value.
///
/// `diff()` writes the replacement sub-entity itself into the patch map, and
/// the generated `toWire()` wraps it here so the decoder never mistakes it for
/// a field-keyed nested patch map (#215).
final class PatchWireReplacement {
  const PatchWireReplacement(this.value);

  /// The replacement sub-entity.
  final Object? value;
}

/// Whether [value]'s ISO-8601 calendar components are in range.
///
/// `DateTime.tryParse` normalizes an out-of-range component instead of
/// rejecting it, so a wire string must be checked before its parse is trusted
/// (#215). A string whose format `tryParse` accepts but this matcher does not
/// recognize is left to `tryParse`'s own validation.
bool _hasValidIsoCalendar(String value) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})'
    r'(?:[T ](\d{2})(?::(\d{2})(?::(\d{2})(?:\.\d+)?)?)?)?',
  ).firstMatch(value);
  if (match == null) return true;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12) return false;
  final daysInMonth = DateTime(year, month + 1, 0).day;
  if (day < 1 || day > daysInMonth) return false;
  final hour = match.group(4) == null ? 0 : int.parse(match.group(4)!);
  final minute = match.group(5) == null ? 0 : int.parse(match.group(5)!);
  final second = match.group(6) == null ? 0 : int.parse(match.group(6)!);
  if (hour > 23 || minute > 59 || second > 59) return false;
  return true;
}
