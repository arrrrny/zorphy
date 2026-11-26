// Deterministic structural probe for the v3 generated surface
// (arrrrny/zorphy#252).
//
// The wall-clock cost guards in `benchmark/` prove the generated patch /
// resolvePath / fromWire surfaces are FAST, but their latency budgets flake
// under host load (the #237 misfire: 739/739 in-suite green, then two
// standalone failures at loadavg ~133 on 12 cores). This probe proves the same
// surfaces are STRUCTURALLY correct with zero timing and zero host-load
// dependence — it is the deterministic half of the pair:
//
//   * ZorphyPatch op counts — `ProductPatch.diff` carries exactly one op per
//     changed field (0 for an identical pair, 1 for a single-field change, 2
//     for a two-field change), and `apply` of the empty patch returns the
//     target by reference.
//   * O(1) switch-table resolvePath coverage — every declared pointer segment
//     resolves to a lens, an unknown segment answers null (never throws), a
//     nested composed pointer descends into the child value, and the generated
//     `resolvePath` is a `switch (pointer)` table with no `RegExp` and no
//     reflective lookup.
//
// It imports the REAL `build_runner`-generated fixtures
// (`benchmark/cost_guard_fixtures.dart` → `_br_/benchmark/…part.dart`), so a
// removed surface fails to COMPILE here — the same loud failure #234 names.
// The launcher (`deterministic_structural_guards_test.dart`) runs generation
// first, then spawns this file's `main`.
//
// Exit 0 = every structural guard green; exit 1 = a structural guard failed.

import 'dart:io';

import '../../benchmark/cost_guard_fixtures.dart';

/// The package root — the parent of this script's `test/audit/` directory —
/// resolved from the script URI so the probe works from any cwd.
Uri get _packageRoot => Platform.script.resolve('../../').normalizePath();

void main() {
  final failures = <String>[];

  void check(String name, bool ok, String detail) {
    if (ok) {
      stdout.writeln('  ok  $name — $detail');
    } else {
      stdout.writeln('  FAIL $name — $detail');
      failures.add(name);
    }
  }

  stdout.writeln('Deterministic structural guards (zorphy#252)');
  stdout.writeln('');

  // ── Guard A: ZorphyPatch op counts ───────────────────────────────────────
  // `ProductPatch.toWire()` emits one entry per SET field, so the op count is
  // exactly the number of fields `diff` marked changed — deterministic,
  // independent of host load.
  stdout.writeln('Guard A: ZorphyPatch op counts');
  final e = Product.fromTrusted(id: 'p1', name: 'widget');

  final noop = ProductPatch.diff(e, e);
  check(
    'identical pair → empty patch',
    noop.isEmpty && noop.toWire().isEmpty,
    'isEmpty=${noop.isEmpty}, ops=${noop.toWire().length}',
  );

  final sameRef = ProductPatch.diff(e, e).apply(e);
  check(
    'apply(empty) returns target by reference',
    identical(sameRef, e),
    'identical=${identical(sameRef, e)}',
  );

  final oneChange = ProductPatch.diff(
    e,
    Product.fromTrusted(id: 'p1', name: 'gadget'),
  );
  check(
    'one changed field → exactly 1 op',
    oneChange.toWire().length == 1 && oneChange.toWire().containsKey('name'),
    'ops=${oneChange.toWire().keys.toList()}',
  );

  final twoChange = ProductPatch.diff(
    e,
    Product.fromTrusted(id: 'p2', name: 'gadget'),
  );
  check(
    'two changed fields → exactly 2 ops',
    twoChange.toWire().length == 2 &&
        twoChange.toWire().containsKey('id') &&
        twoChange.toWire().containsKey('name'),
    'ops=${twoChange.toWire().keys.toList()}',
  );

  // The single-field patch, applied, changes only that field.
  final patched = oneChange.apply(e);
  check(
    'apply(1-op patch) changes only the named field',
    patched.name == 'gadget' && patched.id == 'p1',
    'name=${patched.name}, id=${patched.id}',
  );
  stdout.writeln('');

  // ── Guard B: O(1) switch-table resolvePath coverage ──────────────────────
  // Every declared segment resolves; an unknown segment answers null; the
  // nested composed pointer descends. No timing — pure structure.
  stdout.writeln('Guard B: O(1) switch-table resolvePath coverage');
  final button = ZfaButtonNode.fromTrusted(
    contractId: 'c1',
    mode: 'edit',
    label: 'ok',
  );
  final state = ProductUiState.fromTrusted(
    editDraft: EditDraft.fromTrusted(title: 'draft', price: 1.0),
    selectedTab: 0,
  );

  for (final segment in const <String>[
    '/contractId',
    '/label',
    '/mode',
    '/text',
  ]) {
    final lens = UiNode.resolvePath(segment);
    check(
      'UiNode.resolvePath($segment) resolves to a lens',
      lens != null && lens.path == segment,
      'lens=${lens?.path ?? 'null'}',
    );
  }

  final unknown = UiNode.resolvePath('/doesNotExist');
  check(
    'unknown segment answers null (never throws)',
    unknown == null,
    'lens=${unknown?.path ?? 'null'}',
  );

  final labelLens = UiNode.resolvePath('/label');
  check(
    'lens get dispatches on the runtime subtype',
    labelLens?.get(button) == 'ok',
    'get(button)=${labelLens?.get(button)}',
  );

  final textOnButton = UiNode.resolvePath('/text');
  check(
    'a segment the receiver does not carry answers null',
    textOnButton?.get(button) == null,
    'get(button)=${textOnButton?.get(button)}',
  );

  final priceLens = ProductUiState.resolvePath('/editDraft/price');
  check(
    'composed nested pointer descends into the child value',
    priceLens?.get(state) == 1.0,
    'get(state)=${priceLens?.get(state)}',
  );

  // Structural: the generated resolvePath is a switch table, not a regex or a
  // reflective lookup. Read the generated part and assert the shape.
  final partFile = File(
    '${_packageRoot.toFilePath()}_br_/benchmark/cost_guard_fixtures.part.dart',
  );
  if (partFile.existsSync()) {
    final src = partFile.readAsStringSync();
    final switchTables = 'switch (pointer)'.allMatches(src).length;
    check(
      'resolvePath is a switch table (>= 1 per hierarchy root)',
      switchTables >= 1,
      'switch (pointer) count=$switchTables',
    );
    check(
      'generated output carries no RegExp in resolvePath',
      !src.contains('RegExp'),
      'RegExp present=${src.contains('RegExp')}',
    );
    check(
      'generated output carries no dart:mirrors import',
      !src.contains("import 'dart:mirrors'"),
      'mirrors import present=${src.contains("import 'dart:mirrors'")}',
    );
  } else {
    failures.add('generated part missing');
    stdout.writeln('  FAIL generated part not found at ${partFile.path}');
  }
  stdout.writeln('');

  if (failures.isEmpty) {
    stdout.writeln('ALL STRUCTURAL GUARDS GREEN');
  } else {
    stdout.writeln('${failures.length} STRUCTURAL GUARD(S) FAILED: $failures');
    exitCode = 1;
  }
}
