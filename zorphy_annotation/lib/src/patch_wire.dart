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
      if (parsed != null) return parsed;
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

  /// One field's value, unwrapping the `{"op": "set", "value": …}` spelling a
  /// peer may send in place of the bare value (`toWire()` writes the bare
  /// value, so both are accepted).
  static Object? fieldValue(
    Object? value,
    String path,
    List<FieldViolation> violations,
  ) {
    if (value is Map<String, Object?> && value['op'] == 'set') {
      return value['value'];
    }
    if (value is Map<String, Object?> && value.containsKey('op')) {
      violations.add(
        FieldViolation(
          path: '$path/op',
          expected: "'set'",
          actual: describe(value['op']),
        ),
      );
      return null;
    }
    return value;
  }

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
        final decoded = decodeElement(raw[i], '$path[$i]', violations);
        if (decoded != null) items.add(decoded);
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
    for (var i = 0; i < opsRaw.length; i++) {
      final opPath = '$path/$opsKey[$i]';
      final op = asObject(opsRaw[i], opPath, violations);
      if (op == null) continue;
      switch (op['op']) {
        case 'replaceAll':
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
            final decoded = decodeElement(
              itemsRaw[j],
              '$opPath/items[$j]',
              violations,
            );
            if (decoded != null) items.add(decoded);
          }
          ops.add(ListPatchOp<E>.replaceAll(items));
        case 'append':
          final decoded = decodeElement(op['item'], '$opPath/item', violations);
          if (decoded != null) ops.add(ListPatchOp<E>.append(decoded));
        case 'removeAt':
          final index = as<int>(op['index'], '$opPath/index', violations);
          if (index != null) ops.add(ListPatchOp<E>.removeAt(index));
        case 'updateAt':
          final index = as<int>(op['index'], '$opPath/index', violations);
          final decoded = decodeElement(op['item'], '$opPath/item', violations);
          if (index != null && decoded != null) {
            ops.add(ListPatchOp<E>.updateAt(index, decoded));
          }
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

  /// The delta [raw] carries for a map field, or `null` when it could not be
  /// decoded in full.
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

    if (raw is Map && !raw.containsKey(opsKey)) {
      final entries = <K, V>{};
      for (final entry in raw.entries) {
        final entryPath = '$path/${entry.key}';
        final key = decodeKey(entry.key, entryPath, violations);
        final value = decodeValue(entry.value, entryPath, violations);
        if (key != null && value != null) entries[key] = value;
      }
      if (violations.length != before) return null;
      return MapPatchDelta<K, V>(<MapPatchOp<K, V>>[
        MapPatchOp<K, V>.replaceAll(entries),
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

    final ops = <MapPatchOp<K, V>>[];
    for (var i = 0; i < opsRaw.length; i++) {
      final opPath = '$path/$opsKey[$i]';
      final op = asObject(opsRaw[i], opPath, violations);
      if (op == null) continue;
      switch (op['op']) {
        case 'replaceAll':
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
            final entryPath = '$opPath/entries/${entry.key}';
            final key = decodeKey(entry.key, entryPath, violations);
            final value = decodeValue(entry.value, entryPath, violations);
            if (key != null && value != null) entries[key] = value;
          }
          ops.add(MapPatchOp<K, V>.replaceAll(entries));
        case 'put':
          final key = decodeKey(op['key'], '$opPath/key', violations);
          final value = decodeValue(op['value'], '$opPath/value', violations);
          if (key != null && value != null) {
            ops.add(MapPatchOp<K, V>.put(key, value));
          }
        case 'remove':
          final key = decodeKey(op['key'], '$opPath/key', violations);
          if (key != null) ops.add(MapPatchOp<K, V>.remove(key));
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
