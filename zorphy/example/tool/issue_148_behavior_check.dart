// Behavioral checks for issue #148 (composite list fields must not be
// hard-cast at the generated cast sites). Executed by
// zorphy/test/generation/issue_148_list_map_cast_test.dart via
// `dart run` (cwd: zorphy/example) because the zorphy test package
// cannot import the example package's generated code directly.
//
// Exit code 0 = all checks passed. Any failure prints FAIL and exits 1.
import 'dart:convert';
import 'dart:io';

import 'package:zorphy_example/various/issue_148_list_map_cast_example.dart';

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
  const wire =
      '{"success": true, "marketplaces": [{"url": "https://x"}], '
      '"errors": []}';
  final decoded = jsonDecode(wire) as Map<String, dynamic>;

  // ── fromJson baseline (json_serializable's checked conversion) ──
  final result = MarketplaceResult.fromJson(decoded);
  check(
    'fromJson accepts the raw JSON payload',
    result.success &&
        result.marketplaces.length == 1 &&
        result.marketplaces.first['url'] == 'https://x' &&
        result.errors.isEmpty,
  );

  // ── copyWithField with a raw JSON-decoded list ──────────────────
  // The production crash came through a dynamic-typed call site where
  // the field's type argument erases to dynamic — reproduce that here.
  try {
    final patched = result.copyWithField<dynamic>(
      MarketplaceResultFields.marketplaces,
      decoded['marketplaces'],
    );
    check(
      'copyWithField accepts a raw JSON-decoded list',
      patched.marketplaces.length == 1 &&
          patched.marketplaces.first['url'] == 'https://x' &&
          patched.success,
    );
  } catch (e) {
    print('FAIL: copyWithField accepts a raw JSON-decoded list — threw $e');
    failures.add('copyWithField accepts a raw JSON-decoded list');
  }

  // ── copyWithField with a typed list still works ─────────────────
  final retyped = result.copyWithField(
    MarketplaceResultFields.marketplaces,
    <Map<String, dynamic>>[
      {'url': 'https://y'},
    ],
  );
  check(
    'copyWithField still accepts a typed List<Map<String, dynamic>>',
    retyped.marketplaces.first['url'] == 'https://y',
  );

  // ── patch-merge arm with a raw JSON-decoded list ────────────────
  try {
    final patch = MarketplaceResultPatch()
      ..patchMap[MarketplaceResult$.marketplaces] = decoded['marketplaces']
      ..patchMap[MarketplaceResult$.errors] = decoded['errors'];
    final patched = result.patchWithMarketplaceResult(patch);
    check(
      'patch-merge arm accepts a raw JSON-decoded list',
      patched.marketplaces.length == 1 &&
          patched.marketplaces.first['url'] == 'https://x' &&
          patched.errors.isEmpty,
    );
  } catch (e) {
    print('FAIL: patch-merge arm accepts a raw JSON-decoded list — threw $e');
    failures.add('patch-merge arm accepts a raw JSON-decoded list');
  }

  // ── nullable field: copyWithField(null) keeps the current value ──
  const wire2 = '{"payloads": [{"id": 1}]}';
  final nullable = NullablePayloads.fromJson(jsonDecode(wire2));
  final kept = nullable.copyWithField(
    NullablePayloadsFields.payloads,
    decoded['marketplaces'],
  );
  check(
    'nullable list field accepts a raw JSON-decoded list',
    kept.payloads!.length == 1,
  );

  // ── typed map values (CodeRabbit finding on PR #149) ────────────
  // A field declared List<Map<String, String>> receives decoded
  // Map<String, dynamic> entries at the cast sites; the element cast
  // must convert entry-wise, not throw.
  const typedWire = '{"tags": [{"a": "b"}]}';
  final typedJson = jsonDecode(typedWire) as Map<String, dynamic>;
  final tagged = TaggedResult.fromJson(typedJson);
  check(
    'fromJson baseline for typed map values',
    tagged.tags.first['a'] == 'b' && tagged.maybeTags == null,
  );
  try {
    final patchedTags = tagged.copyWithField<dynamic>(
      TaggedResultFields.tags,
      typedJson['tags'],
    );
    check(
      'copyWithField converts decoded Map<String, dynamic> entries to the declared map type',
      patchedTags.tags.first['a'] == 'b',
    );
    final patchedMaybe = tagged.copyWithField<dynamic>(
      TaggedResultFields.maybeTags,
      typedJson['tags'],
    );
    check(
      'nullable typed-map field converts decoded entries too',
      patchedMaybe.maybeTags!.first['a'] == 'b',
    );
  } catch (e) {
    print('FAIL: typed-map cast sites threw $e');
    failures.add('typed-map cast sites accept decoded entries');
  }

  // Typed input keeps the same instance: the fast path restores the old
  // hard cast's O(1), identity-preserving behavior.
  final typedList = <Map<String, String>>[
    {'e': 'f'},
  ];
  final identityPatched = tagged.copyWithField(
    TaggedResultFields.tags,
    typedList,
  );
  check(
    'copyWithField keeps an already-typed list instance (fast path)',
    identical(identityPatched.tags, typedList),
  );

  // ── patch-merge arm with decoded typed-map entries ──────────────
  try {
    final tagPatch = TaggedResultPatch()
      ..patchMap[TaggedResult$.tags] = typedJson['tags'];
    final tagPatched = tagged.patchWithTaggedResult(tagPatch);
    check(
      'patch-merge arm converts decoded Map<String, dynamic> entries to the declared map type',
      tagPatched.tags.first['a'] == 'b',
    );
  } catch (e) {
    print('FAIL: patch-merge arm typed-map threw $e');
    failures.add('patch-merge arm accepts decoded typed-map entries');
  }

  if (failures.isNotEmpty) {
    print('${failures.length} CHECK(S) FAILED');
    exit(1);
  }
  print('ALL CHECKS PASSED');
}
