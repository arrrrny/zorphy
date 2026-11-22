import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

/// Every constructor parameter name declared by the `final class` named
/// [className] in `lib/src/archetypes.dart`.
///
/// Read from the SOURCE rather than from a live instance: the property under
/// test ("no archetype grows a codegen toggle") is a property of the declared
/// parameters, and an instance can only show the values it was constructed
/// with. `dart:mirrors` is not available under the AOT/VM test configuration
/// this package runs in, and adding `analyzer` as a dev dependency just to
/// reflect over five classes is not worth the resolution cost.
List<String> _constructorParameters(String className) {
  final source = File('lib/src/archetypes.dart').readAsStringSync();
  final classStart = source.indexOf('final class $className ');
  if (classStart < 0) {
    throw StateError('no `final class $className` in archetypes.dart');
  }
  final constIndex = source.indexOf('const $className(', classStart);
  if (constIndex < 0) {
    throw StateError('$className declares no const constructor');
  }
  final open = source.indexOf('(', constIndex);
  final close = _matchingParen(source, open);
  final body = source.substring(open + 1, close);

  return [
    for (final match in RegExp(r'\bthis\.([A-Za-z_$][\w$]*)').allMatches(body))
      match.group(1)!,
  ];
}

int _matchingParen(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    final c = source[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  throw StateError('unbalanced parentheses');
}

void main() {
  group('v3 archetype annotations (issue #176)', () {
    test('ZorphyEntity defaults to the `kind` discriminator', () {
      const entity = ZorphyEntity();
      expect(entity.discriminator, 'kind');
      // Null is the "inherit from my base" state of a subtype; a ROOT that
      // leaves it null fails generation, which is where the entity contract
      // is enforced (the annotation itself cannot know if it is a root).
      expect(entity.principalKey, isNull);
      expect(entity.explicitSubTypes, isEmpty);
    });

    test('ZorphyEntity carries a principal key and explicit subtypes', () {
      const entity = ZorphyEntity(
        principalKey: #id,
        discriminator: 'type',
        explicitSubTypes: [String, int],
      );
      expect(entity.principalKey, #id);
      expect(entity.discriminator, 'type');
      expect(entity.explicitSubTypes, [String, int]);
    });

    test('ZorphyState / ZorphyValue / ZorphyUnion default discriminator', () {
      expect(const ZorphyState().discriminator, 'kind');
      expect(const ZorphyValue().discriminator, 'kind');
      expect(const ZorphyUnion().discriminator, 'kind');
      expect(const ZorphyState().explicitSubTypes, isEmpty);
      expect(const ZorphyValue().explicitSubTypes, isEmpty);
    });

    test('ZorphyIntent requires replaySafe — no default', () {
      const intent = ZorphyIntent(replaySafe: true);
      expect(intent.replaySafe, isTrue);
      expect(intent.discriminator, 'kind');
      expect(intent.explicitSubTypes, isEmpty);
    });

    test('ZorphyMock is a field-level seed hint only', () {
      const mock = ZorphyMock(preset: 'email', example: 'a@b.c');
      expect(mock.preset, 'email');
      expect(mock.example, 'a@b.c');
      expect(const ZorphyMock().preset, isNull);
      expect(const ZorphyMock().example, isNull);
    });

    test('archetype bases are implemented by the matching classes', () {
      const entity = ZorphyEntity();
      const state = ZorphyState();
      const union = ZorphyUnion();
      const intent = ZorphyIntent(replaySafe: false);
      const value = ZorphyValue();

      expect(entity, isA<ZorphyEntityBase<Symbol?>>());
      expect(entity, isA<ZorphyPolymorphicBase>());
      expect(state, isA<ZorphyStateBase>());
      expect(state, isA<ZorphyPolymorphicBase>());
      expect(union, isA<ZorphyUnionBase>());
      expect(union, isA<ZorphyPolymorphicBase>());
      expect(intent, isA<ZorphyIntentBase>());
      expect(intent, isA<ZorphyPolymorphicBase>());
      expect(value, isA<ZorphyValueBase>());
      expect(value, isA<ZorphyPolymorphicBase>());
    });

    // Guards the property this PR exists for: the archetypes must never grow a
    // `generate*` codegen toggle. The previous version asserted on
    // `toString()`, which is `Instance of 'ZorphyEntity'` for all of them and
    // so could never fail; this reads the declared constructor parameters,
    // which is what adding a flag actually changes.
    test('no archetype declares a codegen toggle parameter', () {
      const allowed = {
        'ZorphyEntity': {'principalKey', 'discriminator', 'explicitSubTypes'},
        'ZorphyState': {'discriminator', 'explicitSubTypes'},
        'ZorphyUnion': {'discriminator'},
        'ZorphyIntent': {'replaySafe', 'discriminator', 'explicitSubTypes'},
        'ZorphyValue': {'discriminator', 'explicitSubTypes'},
        'ZorphyMock': {'preset', 'example'},
      };

      for (final entry in allowed.entries) {
        final parameters = _constructorParameters(entry.key);
        expect(
          parameters,
          isNotEmpty,
          reason: '${entry.key} declares no `this.` parameters',
        );
        expect(
          parameters.where((p) => p.startsWith('generate')),
          isEmpty,
          reason: '${entry.key} must not carry a codegen toggle',
        );
        expect(
          parameters.toSet(),
          entry.value,
          reason:
              '${entry.key} declares ${parameters.toSet()}; the v3 surface is '
              'exactly ${entry.value}',
        );
      }
    });
  });
}
