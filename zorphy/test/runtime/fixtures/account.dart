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
    final composed = AccountPatch()
      ..patchMap.addAll(patchMap)
      ..patchMap.addAll(next.patchMap);
    return composed;
  }

  @override
  String wireNameFor(Account$ key) {
    return switch (key) {
      Account$.id => 'id',
      Account$.name_ => 'name',
      Account$.score => 'score',
      Account$.note => 'note',
      Account$.tier => 'tier',
    };
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
    if (patchMap.containsKey(Account$.tier)) {
      final value = patchMap[Account$.tier];
      wire['tier'] = value is Enum ? value.name : value;
    }
    return wire;
  }

  static ZorphyBoundaryResult<AccountPatch> fromWire(Map<String, Object?> raw) {
    final violations = <FieldViolation>[];
    final ops = ZorphyPatchWire.opsOf(raw, '', violations);
    final prefix = ZorphyPatchWire.opsPathOf(raw);
    if (ops != null) {
      final patch = AccountPatch();
      if (ops.containsKey('id')) {
        final Object? idRaw = ZorphyPatchWire.fieldValue(
          ops['id'],
          '$prefix/id',
          violations,
        );
        if (idRaw == null) {
          violations.add(
            FieldViolation(
              path: '$prefix/id',
              expected: 'String',
              actual: ZorphyPatchWire.describe(null),
            ),
          );
        } else {
          final before = violations.length;
          final decoded = ZorphyPatchWire.as<String>(
            idRaw,
            '$prefix/id',
            violations,
          );
          if (violations.length == before) {
            patch.patchMap[Account$.id] = decoded;
          }
        }
      }
      if (ops.containsKey('name')) {
        final Object? nameRaw = ZorphyPatchWire.fieldValue(
          ops['name'],
          '$prefix/name',
          violations,
        );
        if (nameRaw == null) {
          violations.add(
            FieldViolation(
              path: '$prefix/name',
              expected: 'String',
              actual: ZorphyPatchWire.describe(null),
            ),
          );
        } else {
          final before = violations.length;
          final decoded = ZorphyPatchWire.as<String>(
            nameRaw,
            '$prefix/name',
            violations,
          );
          if (violations.length == before) {
            patch.patchMap[Account$.name_] = decoded;
          }
        }
      }
      if (ops.containsKey('score')) {
        final Object? scoreRaw = ZorphyPatchWire.fieldValue(
          ops['score'],
          '$prefix/score',
          violations,
        );
        if (scoreRaw == null) {
          violations.add(
            FieldViolation(
              path: '$prefix/score',
              expected: 'int',
              actual: ZorphyPatchWire.describe(null),
            ),
          );
        } else {
          final before = violations.length;
          final decoded = ZorphyPatchWire.as<int>(
            scoreRaw,
            '$prefix/score',
            violations,
          );
          if (violations.length == before) {
            patch.patchMap[Account$.score] = decoded;
          }
        }
      }
      if (ops.containsKey('note')) {
        final Object? noteRaw = ZorphyPatchWire.fieldValue(
          ops['note'],
          '$prefix/note',
          violations,
        );
        if (noteRaw == null) {
          patch.patchMap[Account$.note] = null;
        } else {
          final before = violations.length;
          final decoded = ZorphyPatchWire.as<String>(
            noteRaw,
            '$prefix/note',
            violations,
          );
          if (violations.length == before) {
            patch.patchMap[Account$.note] = decoded;
          }
        }
      }
      if (ops.containsKey('tier')) {
        final Object? tierRaw = ZorphyPatchWire.fieldValue(
          ops['tier'],
          '$prefix/tier',
          violations,
        );
        if (tierRaw == null) {
          violations.add(
            FieldViolation(
              path: '$prefix/tier',
              expected: 'AccountTier',
              actual: ZorphyPatchWire.describe(null),
            ),
          );
        } else {
          final before = violations.length;
          final decoded = ZorphyPatchWire.enumByName<AccountTier>(
            AccountTier.values,
            tierRaw,
            '$prefix/tier',
            violations,
          );
          if (violations.length == before) {
            patch.patchMap[Account$.tier] = decoded;
          }
        }
      }
      if (violations.isEmpty) return BoundaryOk<AccountPatch>(patch);
    }
    return BoundaryErr<AccountPatch>(
      targetType: 'AccountPatch',
      violations: violations,
    );
  }

  Map<String, Object?> toEnvelope({Object? principalKey}) {
    final envelope = <String, Object?>{
      'entityType': 'Account',
      'patchKind': 'Account',
      'principalKey': principalKey,
      'ops': toWire(),
    };
    return envelope;
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
