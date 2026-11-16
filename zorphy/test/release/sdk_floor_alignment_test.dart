import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Parses the `environment: sdk` constraint from a `pubspec.yaml` file.
VersionConstraint _sdkConstraintFor(String pubspecPath) {
  final content = File(pubspecPath).readAsStringSync();
  final yaml = loadYaml(content) as YamlMap;
  final environment = yaml['environment'] as YamlMap?;
  final sdkValue = environment?['sdk'];
  expect(
    sdkValue,
    isA<String>(),
    reason: '$pubspecPath must declare environment: sdk',
  );
  return VersionConstraint.parse(sdkValue as String);
}

void main() {
  group('SDK floor alignment (2.5.0)', () {
    test('zorphy declares an SDK floor of >=3.11.0', () {
      final constraint = _sdkConstraintFor('pubspec.yaml');
      expect(constraint.allows(Version(3, 11, 0)), isTrue);
      expect(constraint.allows(Version(3, 10, 9)), isFalse);
      expect(constraint.allows(Version(3, 8, 0)), isFalse);
      expect(constraint.allows(Version(3, 13, 0)), isTrue);
    });

    test('zorphy_migrator declares an SDK floor of >=3.11.0', () {
      final constraint = _sdkConstraintFor('../zorphy_migrator/pubspec.yaml');
      expect(constraint.allows(Version(3, 11, 0)), isTrue);
      expect(constraint.allows(Version(3, 10, 9)), isFalse);
      expect(constraint.allows(Version(3, 8, 0)), isFalse);
      expect(constraint.allows(Version(3, 13, 0)), isTrue);
    });

    test('direct dependencies support the 3.11.0 floor', () {
      final yaml = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      final deps = yaml['dependencies'] as YamlMap;
      expect(
        deps.keys,
        containsAll(<String>[
          'analyzer',
          'build',
          'source_gen',
          'dart_style',
          'code_builder',
          'meta',
        ]),
      );
    });
  });
}
