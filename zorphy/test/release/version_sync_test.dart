import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

String _versionOf(String pubspecPath) {
  final yaml = loadYaml(File(pubspecPath).readAsStringSync()) as YamlMap;
  return yaml['version'] as String;
}

void main() {
  group('version sync (2.5.1)', () {
    test('zorphy is at 2.5.1', () {
      expect(_versionOf('pubspec.yaml'), '2.5.1');
    });

    test('zorphy_annotation is at 2.5.1', () {
      expect(_versionOf('../zorphy_annotation/pubspec.yaml'), '2.5.1');
    });

    test('zorphy and zorphy_annotation versions match', () {
      expect(
        _versionOf('pubspec.yaml'),
        _versionOf('../zorphy_annotation/pubspec.yaml'),
      );
    });

    test('both CHANGELOGs carry a 2.5.1 entry', () {
      expect(File('CHANGELOG.md').readAsStringSync(), contains('## [2.5.1]'));
      expect(
        File('../zorphy_annotation/CHANGELOG.md').readAsStringSync(),
        contains('## [2.5.1]'),
      );
    });
  });
}
