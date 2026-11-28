// Behavioral checks for PR #349 (`_sanitizeJson` preserves typed list value
// type). Executed by
// zorphy/test/generation/sanitize_json_typed_list_test.dart via `dart run`
// (cwd: zorphy/example) because the zorphy test package cannot import the
// example package's generated code directly.
//
// Exit code 0 = all checks passed. Any failure prints FAIL and exits 1.
import 'dart:io';

import 'package:zorphy_example/various/sanitize_json_typed_list_example.dart';

final List<String> failures = <String>[];

void check(String name, bool condition) {
  if (condition) {
    print('PASS: $name');
  } else {
    failures.add(name);
    print('FAIL: $name');
  }
}

void main() {
  // ── typed inner map with a mutable typed list ───────────────────
  // The generated `_sanitizeJson` recurses into the typed inner map
  // (`Map<String, List<Map<String, dynamic>>>`) and must keep the inner
  // list's runtime type — the original crash was a `List<dynamic>` landing
  // in a `List<Map<String, dynamic>>` slot.
  final typed = SanitizeTypedListExample(
    cleaners: <String, List<Map<String, dynamic>>>{
      'options': <Map<String, dynamic>>[
        {'id': 1},
        {'id': 2},
      ],
    },
  );
  final lean = typed.toJsonLean();
  final cleaners = lean['cleaners'];
  check(
    'cleaners survives as a Map<String, dynamic>',
    cleaners is Map<String, dynamic>,
  );
  final innerList = (cleaners as Map<String, dynamic>)['options'];
  check(
    'inner list keeps runtime type List<Map<String, dynamic>>',
    innerList is List<Map<String, dynamic>>,
  );
  check(
    'inner list contents are preserved',
    innerList is List &&
        innerList.length == 2 &&
        (innerList.first as Map)['id'] == 1 &&
        (innerList.last as Map)['id'] == 2,
  );

  // ── unmodifiable inner list (the Major finding) ─────────────────
  // A manual `toJson` converter may return an unmodifiable list. The old
  // `json[i] = _sanitizeJson(json[i])` branch threw on the slot assignment;
  // the fix sanitizes each element without assigning, so an unmodifiable
  // list survives `toJsonLean()`.
  final unmodifiable = SanitizeTypedListExample(
    cleaners: <String, List<Map<String, dynamic>>>{
      'options': List<Map<String, dynamic>>.unmodifiable(<Map<String, dynamic>>[
        {'id': 7},
      ]),
    },
  );
  try {
    final lean2 = unmodifiable.toJsonLean();
    final inner2 = (lean2['cleaners'] as Map<String, dynamic>)['options'];
    check(
      'unmodifiable inner list survives sanitize without throwing',
      inner2 is List<Map<String, dynamic>> &&
          inner2.length == 1 &&
          (inner2.first as Map)['id'] == 7,
    );
  } catch (e) {
    print('FAIL: unmodifiable inner list survives sanitize — threw $e');
    failures.add('unmodifiable inner list survives sanitize');
  }

  if (failures.isNotEmpty) {
    print('${failures.length} CHECK(S) FAILED');
    exit(1);
  }
  print('ALL CHECKS PASSED');
}
