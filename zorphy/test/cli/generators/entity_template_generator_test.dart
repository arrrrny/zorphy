// Regression tests for arrrrny/zorphy#297: a fieldless `@ZorphyEntity`
// scaffold promises `principalKey: #id` but never declared an `id` field,
// so the builder failed with ZORPHY_E001 on every fieldless entity.
//
// The v3 annotation surface is zero-toggle (issue #233): an entity's
// identity is unconditional, so the scaffold MUST declare `String get id;`
// whenever the caller listed no `id` field. A class that implements another
// interface inherits its identity instead and is not redeclared.

import 'package:test/test.dart';
import 'package:zorphy/src/cli/generators/entity_template_generator.dart';
import 'package:zorphy/src/cli/models/entity_config.dart';

String _generate(EntityConfig config) =>
    EntityTemplateGenerator.generate(config, const []);

void main() {
  group('EntityTemplateGenerator fieldless entity (#297)', () {
    test('declares `String get id;` when no fields are listed', () {
      const config = EntityConfig(name: 'Todo');
      final out = _generate(config);

      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
      expect(
        out,
        contains('String get id;'),
        reason: 'the principalKey #id must name a declared field',
      );
    });

    test('does not redeclare id when the caller listed an id field', () {
      const config = EntityConfig(
        name: 'Todo',
        fields: [FieldDefinition(name: 'id', type: 'String')],
      );
      final out = _generate(config);

      // Exactly one id getter — the declared field, never a duplicate.
      expect('String get id;'.allMatches(out), hasLength(1));
    });

    test('inherits identity (no id) when it implements an interface', () {
      const config = EntityConfig(name: 'Todo', extendsInterface: 'Base');
      final out = _generate(config);

      expect(out, contains('implements \$Base'));
      expect(out, isNot(contains('String get id;')));
    });

    test('a value object declares no id', () {
      const config = EntityConfig(name: 'Todo', kind: ZorphyKind.valueObject);
      final out = _generate(config);

      expect(out, contains('@ZorphyValue()'));
      expect(out, isNot(contains('String get id;')));
    });
  });
}
