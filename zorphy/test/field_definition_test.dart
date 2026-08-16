import 'package:test/test.dart';
import 'package:zorphy/zorphy.dart';

void main() {
  group('FieldDefinition.parse', () {
    test('parses plain name:type', () {
      final f = FieldDefinition.parse('id:String');
      expect(f.name, 'id');
      expect(f.type, 'String');
      expect(f.nullable, isFalse);
      expect(f.jsonName, isNull);
      expect(f.fullType, 'String');
    });

    test('parses nullable type', () {
      final f = FieldDefinition.parse('note:String?');
      expect(f.name, 'note');
      expect(f.type, 'String');
      expect(f.nullable, isTrue);
      expect(f.fullType, 'String?');
    });

    test('parses generic list type', () {
      final f = FieldDefinition.parse('countries:List<Country>');
      expect(f.name, 'countries');
      expect(f.type, 'List<Country>');
      expect(f.fullType, 'List<Country>');
    });

    test('parses name:type:json=<wireName>', () {
      final f = FieldDefinition.parse('in_:String:json=in');
      expect(f.name, 'in_');
      expect(f.type, 'String');
      expect(f.jsonName, 'in');
    });

    test('parses wire name for GraphQL _and operator', () {
      final f = FieldDefinition.parse(
        'and:ProductFilterParameter:json=_and',
      );
      expect(f.name, 'and');
      expect(f.type, 'ProductFilterParameter');
      expect(f.jsonName, '_and');
    });

    test('rejects malformed meta segment', () {
      expect(
        () => FieldDefinition.parse('in_:String:wire=in'),
        throwsArgumentError,
      );
    });

    test('rejects empty json= wire name', () {
      expect(
        () => FieldDefinition.parse('in_:String:json='),
        throwsArgumentError,
      );
    });

    test('rejects definitions with too many parts', () {
      expect(
        () => FieldDefinition.parse('a:String:json=x:extra'),
        throwsArgumentError,
      );
    });

    test('rejects definitions with a single part', () {
      expect(() => FieldDefinition.parse('id'), throwsArgumentError);
    });
  });

  group('FieldDefinition.copyWith', () {
    test('preserves jsonName when not overridden', () {
      final f = FieldDefinition.parse('in_:String:json=in');
      final copy = f.copyWith(type: 'int');
      expect(copy.name, 'in_');
      expect(copy.type, 'int');
      expect(copy.jsonName, 'in');
    });
  });
}
