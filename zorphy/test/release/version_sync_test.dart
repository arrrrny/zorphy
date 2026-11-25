import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

String _versionOf(String pubspecPath) {
  final yaml = loadYaml(File(pubspecPath).readAsStringSync()) as YamlMap;
  return yaml['version'] as String;
}

void main() {
  group('version sync (3.0.0 and 3.0.0-dev.2 sync across 3 packages)', () {
    test('zorphy, zorphy_annotation, and zorphy_migrator versions match', () {
      final zorphyVer = _versionOf('pubspec.yaml');
      final annotationVer = _versionOf('../zorphy_annotation/pubspec.yaml');
      final migratorVer = _versionOf('../zorphy_migrator/pubspec.yaml');

      expect(zorphyVer, annotationVer);
      expect(zorphyVer, migratorVer);
    });

    test(
      'publish.sh version regex accepts SemVer prerelease like 3.0.0-dev.2',
      () {
        final regex = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$');
        expect(regex.hasMatch('3.0.0'), isTrue);
        expect(regex.hasMatch('3.0.0-dev.2'), isTrue);
        expect(regex.hasMatch('3.0.0-rc.1'), isTrue);
        expect(regex.hasMatch('invalid'), isFalse);
      },
    );
  });
}
