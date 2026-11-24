// Runtime fixture for ISSUE-007 (zorphy#182).
//
// `Account` and `AccountPatch` stand in for what the generator emits for a
// concrete `@ZorphyEntity`: the entity mirror plus its field enum, and a patch
// carrying the full algebra (`diff`/`apply`/`compose`/`invert`/`isEmpty`/
// `toWire`) next to the legacy fluent builders (`with*`).
//
// The PATCH section between the markers is byte-identical to
// `PatchEmitter`'s output for this entity — `test/golden/patch_golden_test.dart`
// compares them, so a change to the emitter fails that test until the fixture
// (and therefore this real, exercised patch) is regenerated deliberately.

import 'package:zorphy_annotation/zorphy.dart';

enum AccountTier { free, pro, enterprise }

/// The entity's field enum, as `FieldEnumGenerator` emits it — note the
/// reserved-member escape: a field named `name` becomes `name_`.
enum Account$ { id, name_, score, note, tier }

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.score,
    this.note,
    this.tier = AccountTier.free,
  });

  final String id;
  final String name;
  final int score;
  final String? note;
  final AccountTier tier;

  Account copyWith({
    String? id,
    String? name,
    int? score,
    String? note,
    AccountTier? tier,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      note: note ?? this.note,
      tier: tier ?? this.tier,
    );
  }

  Account patchWithAccount(AccountPatch? patchInput) {
    final _patcher = patchInput ?? AccountPatch();
    final _patchMap = _patcher.patchMap;
    return Account(
      id: _patchMap.containsKey(Account$.id)
          ? _patchMap[Account$.id] as String
          : this.id,
      name: _patchMap.containsKey(Account$.name_)
          ? _patchMap[Account$.name_] as String
          : this.name,
      score: _patchMap.containsKey(Account$.score)
          ? _patchMap[Account$.score] as int
          : this.score,
      note: _patchMap.containsKey(Account$.note)
          ? _patchMap[Account$.note] as String?
          : this.note,
      tier: _patchMap.containsKey(Account$.tier)
          ? _patchMap[Account$.tier] as AccountTier
          : this.tier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          score == other.score &&
          note == other.note &&
          tier == other.tier;

  @override
  int get hashCode => Object.hash(id, name, score, note, tier);

  @override
  String toString() =>
      'Account(id: $id, name: $name, score: $score, note: $note, tier: $tier)';
}

// GOLDEN-PATCH-START
class AccountPatch extends PatchBase<Account, Account$> {
  const AccountPatch.empty() : super.empty();

  AccountPatch() : super();

  /// The canonical empty patch: no change, allocations.
  static const AccountPatch emptyPatch = AccountPatch.empty();

  bool get isEmpty {
    return patchMap.isEmpty;
  }

  Account apply(Account target) {
    if (isEmpty) return target;
    return target.patchWithAccount(this);
  }

  Account applyTo(Account entity) {
    return apply(entity);
  }

  AccountPatch compose(covariant AccountPatch next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    return AccountPatch()
      ..patchMap.addAll(patchMap)
      ..patchMap.addAll(next.patchMap);
  }

  AccountPatch invert(Account before) {
    final undo = AccountPatch();
    if (patchMap.containsKey(Account$.id))
      undo.patchMap[Account$.id] = before.id;
    if (patchMap.containsKey(Account$.name_))
      undo.patchMap[Account$.name_] = before.name;
    if (patchMap.containsKey(Account$.score))
      undo.patchMap[Account$.score] = before.score;
    if (patchMap.containsKey(Account$.note))
      undo.patchMap[Account$.note] = before.note;
    if (patchMap.containsKey(Account$.tier))
      undo.patchMap[Account$.tier] = before.tier;
    return undo;
  }

  static AccountPatch diff(Account previous, Account next) {
    if (identical(previous, next)) return const AccountPatch.empty();
    final changes = AccountPatch();
    if (previous.id != next.id) changes.patchMap[Account$.id] = next.id;
    if (previous.name != next.name)
      changes.patchMap[Account$.name_] = next.name;
    if (previous.score != next.score)
      changes.patchMap[Account$.score] = next.score;
    if (previous.note != next.note) changes.patchMap[Account$.note] = next.note;
    if (previous.tier != next.tier) changes.patchMap[Account$.tier] = next.tier;
    return changes;
  }

  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (patchMap.containsKey(Account$.id)) wire['id'] = patchMap[Account$.id];
    if (patchMap.containsKey(Account$.name_))
      wire['name'] = patchMap[Account$.name_];
    if (patchMap.containsKey(Account$.score))
      wire['score'] = patchMap[Account$.score];
    if (patchMap.containsKey(Account$.note))
      wire['note'] = patchMap[Account$.note];
    if (patchMap.containsKey(Account$.tier))
      wire['tier'] = patchMap[Account$.tier];
    return wire;
  }

  AccountPatch withId(String? value) {
    patchMap[Account$.id] = value;
    return this;
  }

  AccountPatch withName(String? value) {
    patchMap[Account$.name_] = value;
    return this;
  }

  AccountPatch withScore(int? value) {
    patchMap[Account$.score] = value;
    return this;
  }

  AccountPatch withNote(String? value) {
    patchMap[Account$.note] = value;
    return this;
  }

  AccountPatch withTier(AccountTier? value) {
    patchMap[Account$.tier] = value;
    return this;
  }
}

// GOLDEN-PATCH-END
