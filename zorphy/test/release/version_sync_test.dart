import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

String _versionOf(String pubspecPath) {
  final yaml = loadYaml(File(pubspecPath).readAsStringSync()) as YamlMap;
  return yaml['version'] as String;
}

void main() {
  group('version sync (3.0.0)', () {
    test('zorphy is at 3.0.0', () {
      expect(_versionOf('pubspec.yaml'), '3.0.0');
    });

    test('zorphy_annotation is at 3.0.0', () {
      expect(_versionOf('../zorphy_annotation/pubspec.yaml'), '3.0.0');
    });

    test('zorphy and zorphy_annotation versions match', () {
      expect(
        _versionOf('pubspec.yaml'),
        _versionOf('../zorphy_annotation/pubspec.yaml'),
      );
    });

    test('both CHANGELOGs carry a 3.0.0 entry', () {
      expect(File('CHANGELOG.md').readAsStringSync(), contains('## [3.0.0]'));
      expect(
        File('../zorphy_annotation/CHANGELOG.md').readAsStringSync(),
        contains('## [3.0.0]'),
      );
    });
  });
}
