import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Parses the `environment: sdk` constraint from a `pubspec.yaml` file.
VersionConstraint _sdkConstraintFor(String pubspecPath) {
  expect(
    File(pubspecPath).existsSync(),
    isTrue,
    reason: 'Missing $pubspecPath',
  );
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

    test('resolved direct dependencies support the 3.11.0 floor', () {
      final configFile = File('.dart_tool/package_config.json');
      expect(
        configFile.existsSync(),
        isTrue,
        reason: 'Run dart pub get in zorphy/ first',
      );
      final cfg =
          jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
      final packages = (cfg['packages'] as List).cast<Map<String, dynamic>>();

      const coreDeps = <String>[
        'analyzer',
        'build',
        'source_gen',
        'dart_style',
        'code_builder',
        'meta',
      ];

      final byName = {for (final pkg in packages) pkg['name'] as String: pkg};
      for (final name in coreDeps) {
        final pkg = byName[name];
        expect(pkg, isNotNull, reason: '$name must be a resolved dependency');
        final rootUri = pkg!['rootUri'] as String;
        final pubspecPath = rootUri.startsWith('file://')
            ? Uri.parse(rootUri).toFilePath()
            : p.normalize(p.join('.dart_tool', rootUri));
        final depConstraint = _sdkConstraintFor('$pubspecPath/pubspec.yaml');
        expect(
          depConstraint.allows(Version(3, 13, 0)),
          isTrue,
          reason:
              '$name SDK constraint (${pkg['rootUri']}) must admit the dev SDK 3.13.0',
        );
        if (name != 'code_builder' && name != 'meta') {
          expect(
            depConstraint.allows(Version(3, 10, 9)),
            isFalse,
            reason:
                '$name SDK constraint (${pkg['rootUri']}) must exclude Dart 3.10.9',
          );
        }
      }

      // The locked analyzer on Dart 3.13+ is 14.7.0 (sdk: ^3.13.0); the
      // 3.11-compatible 14.x release a Dart 3.11 resolution picks inside
      // `^14.0.0` is 14.1.0 (sdk: ^3.11.0). Its pubspec comes from a
      // repository-owned fixture rather than the pub cache: published versions
      // are immutable, while the cache is ambient — CI resolves ^14.0.0 to the
      // newest 14.x and never downloads 14.1.0, so a cache lookup made this
      // test pass or fail on machine state alone.
      final analyzerFloorConstraint = _sdkConstraintFor(
        'test/release/fixtures/analyzer-14.1.0.pubspec.yaml',
      );
      expect(
        analyzerFloorConstraint.allows(Version(3, 11, 0)),
        isTrue,
        reason: 'analyzer 14.1.0 must admit Dart 3.11.0',
      );
      expect(
        analyzerFloorConstraint.allows(Version(3, 10, 9)),
        isFalse,
        reason: 'analyzer 14.1.0 must reject Dart 3.10.9',
      );
    });
  });
}
