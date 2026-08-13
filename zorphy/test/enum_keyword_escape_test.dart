import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/zorphy.dart';

void main() {
  group('createEnum keyword escaping and wire names', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('zorphy_enum_test_');
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    Future<String> generate({
      required String name,
      required List<String> values,
    }) async {
      final creator = EntityCreator(baseOutputDir: tmp.path);
      final result = await creator.createEnum(
        EnumConfig(name: name, outputDir: tmp.path, values: values),
      );
      expect(result.isSuccess, isTrue, reason: result.error);
      return File(result.filePath).readAsString();
    }

    test('plain values are emitted verbatim', () async {
      final src = await generate(name: 'SortOrder', values: ['ASC', 'DESC']);
      expect(src, contains('enum SortOrder {'));
      expect(src, contains('ASC'));
      expect(src, contains('DESC'));
      expect(src, isNot(contains('@JsonValue')));
    });

    test('Dart keyword values are auto-escaped with @JsonValue', () async {
      final src = await generate(
        name: 'LanguageCode',
        values: ['as', 'de_AT', 'is', 'zh_Hans'],
      );
      expect(src, contains('@JsonValue(\'as\')'));
      expect(src, contains('as_'));
      expect(src, contains('@JsonValue(\'is\')'));
      expect(src, contains('is_'));
      expect(src, contains('de_AT'));
      expect(src, contains('zh_Hans'));
      expect(src, contains(
        "import 'package:json_annotation/json_annotation.dart';",
      ));
    });

    test('explicit member:wire pairs are emitted with @JsonValue', () async {
      final src = await generate(
        name: 'CurrencyCode',
        values: ['aed:AED', 'try_:TRY'],
      );
      expect(src, contains("@JsonValue('AED')"));
      expect(src, contains('aed'));
      expect(src, contains("@JsonValue('TRY')"));
      expect(src, contains('try_'));
    });

    test('generated source with keyword values compiles', () async {
      final dir = Directory('${tmp.path}/lib/src/domain/entities');
      await dir.create(recursive: true);
      final src = await generate(
        name: 'LanguageCode',
        values: ['as', 'de_AT', 'is'],
      );
      // A plain identifier check is enough — the member must be a valid token.
      expect(src, isNot(RegExp(r'\bas\b,')));
      expect(src, isNot(RegExp(r'\bis\b,')));
      expect(src, contains('as_'));
      expect(src, contains('is_'));
    });
  });
}
