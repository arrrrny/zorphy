import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Parses `pubspec.lock` into a flat `package -> version` map.
Map<String, String> _lockVersions(String lockPath) {
  final lock = loadYaml(File(lockPath).readAsStringSync()) as YamlMap;
  final packages = lock['packages'] as YamlMap;
  final versions = <String, String>{};
  for (final entry in packages.entries) {
    final pkg = entry.key as String;
    final body = entry.value as YamlMap;
    final version = body['version'];
    if (version is String) versions[pkg] = version;
  }
  return versions;
}

bool _atLeast(String version, int wantMajor, int wantMinor, int wantPatch) {
  final parts = version.split('.');
  final major = int.parse(parts[0]);
  final minor = int.parse(parts[1]);
  final patch = int.parse(parts[2]);
  if (major != wantMajor) return major > wantMajor;
  if (minor != wantMinor) return minor > wantMinor;
  return patch >= wantPatch;
}

/// The built_collection 6.0.0 graph exists only where
/// `pubspec_overrides.yaml` carries the built_value git pin. The CI
/// analyzer_compat matrix rewrites that file with its own analyzer pins,
/// dropping the pin, so built_collection legitimately re-resolves to
/// built_value's hosted `^5.0.0` there and this assertion does not apply.
final bool _builtValueOverrideInEffect =
    File('pubspec_overrides.yaml').existsSync() &&
    File('pubspec_overrides.yaml').readAsStringSync().contains('built_value:');

void main() {
  group('2.5.x transitive upgrades (issue #173)', () {
    test(
      'zorphy dev graph resolves built_collection 6.0.0',
      () {
        final versions = _lockVersions('pubspec.lock');
        expect(
          versions['built_collection'],
          '6.0.0',
          reason:
              'issue #173: built_collection 6.0.0 was left on the table by the '
              '2.5.1 publish (locked ${versions['built_collection']}). Master '
              'already runs 6.0.0 through the built_value git override (PR '
              '#169); the 2.5.x line must take the same development-only '
              'override without changing any declared constraint.',
        );
      },
      skip: _builtValueOverrideInEffect
          ? null
          : 'pubspec_overrides.yaml carries no built_value pin (analyzer_compat '
                'leg rewrote it) — built_collection stays at built_value\'s '
                'hosted ^5.0.0 there',
    );

    test('coverage is at least 1.16.1', () {
      final versions = _lockVersions('pubspec.lock');
      final version = versions['coverage'];
      expect(version, isNotNull);
      expect(
        _atLeast(version!, 1, 16, 1),
        isTrue,
        reason:
            'issue #173: coverage 1.16.1 was left on the table by the 2.5.1 '
            'publish (locked $version) — a plain dev-lockfile upgrade, no-op '
            'for the published artifact.',
      );
    });
  });
}
