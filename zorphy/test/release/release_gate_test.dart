import 'dart:io';

import 'package:test/test.dart';

/// Regression gate for issue #314: `publish.sh` must run a clean-checkout CI
/// simulation (the release gate) BEFORE it publishes or pushes.
///
/// `3.0.0-dev.4` shipped base-red because every guard ran on the maintainer's
/// dev tree — fresh local locks and a gitignored `pubspec_overrides.yaml` — not
/// against the pristine clone CI actually checks out. These tests pin the gate
/// into `publish.sh`: they fail on a tree whose `publish.sh` publishes without
/// simulating the clean checkout, and pass once the gate is wired in ahead of
/// the publish/push steps.

/// The repository root: this test runs with the `zorphy` package as cwd (the
/// documented `dart test` invocation) and the package sits directly under it.
final String _repoRoot = Directory(
  '${Directory.current.path}/..',
).resolveSymbolicLinksSync();

String _read(String relative) =>
    File('$_repoRoot/$relative').readAsStringSync();

/// Writes [files] (relative path to content) under [root], creating parents.
void _writeLayout(Directory root, Map<String, String> files) {
  for (final entry in files.entries) {
    File('${root.path}/${entry.key}')
      ..createSync(recursive: true)
      ..writeAsStringSync(entry.value);
  }
}

void main() {
  group('publish.sh release gate (issue #314)', () {
    const version = '9.9.9-dev.1';
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('zorphy_release_gate_');
      _writeLayout(root, {
        'scripts/publish.sh': _read('scripts/publish.sh'),
        'README.md': _read('README.md'),
        'zorphy_annotation/pubspec.yaml': _read(
          'zorphy_annotation/pubspec.yaml',
        ),
        'zorphy_annotation/CHANGELOG.md': _read(
          'zorphy_annotation/CHANGELOG.md',
        ),
        'zorphy/pubspec.yaml': _read('zorphy/pubspec.yaml'),
        'zorphy/CHANGELOG.md': _read('zorphy/CHANGELOG.md'),
        'zorphy_migrator/pubspec.yaml': _read('zorphy_migrator/pubspec.yaml'),
        'zorphy_migrator/CHANGELOG.md': '# Changelog\n',
      });
    });

    tearDown(() => root.deleteSync(recursive: true));

    Future<ProcessResult> publishDryRun() => Process.run('bash', [
      'scripts/publish.sh',
      version,
      'release gate probe',
      '--dry-run',
    ], workingDirectory: root.path);

    test(
      '--dry-run plans the clean-checkout gate before any publish',
      () async {
        final result = await publishDryRun();
        final out = '${result.stdout}\n${result.stderr}';

        expect(result.exitCode, 0, reason: out);

        // The gate is announced and planned as a dry-run step.
        expect(
          out,
          contains('Running pre-publish gate'),
          reason: 'publish.sh must announce the pre-publish gate',
        );

        // The pre-publish gate simulates the satisfiability checks against a
        // pristine clone of the release commit: a fresh `git clone`, version
        // sync, a resolve-allowed `dart pub get` per package (NOT
        // --enforce-lockfile, which is unpassable for a version bump — issue
        // #325), the format check from zorphy/, and the release guard suite.
        final dryRunSteps = RegExp(r'\[dry-run\] (.*)').allMatches(out);
        final commands = dryRunSteps.map((m) => m.group(1)!).toList();
        expect(
          commands,
          containsAll(<Matcher>[
            contains('git clone file://'),
            contains('scripts/check_version_sync.sh'),
            contains('dart format --output=none --set-exit-if-changed'),
            contains('dart test test/release/'),
          ]),
          reason: out,
        );

        // The pre-publish gate resolves (resolve-allowed) but never enforces a
        // lock against the unpublished version; the enforce-lockfile gate lives
        // in the post-publish phase, which is planned AFTER the publish step.
        final prePublishIndex = out.indexOf('Running pre-publish gate');
        final postPublishIndex = out.indexOf(
          'Running post-publish verification',
        );
        final publishIndex = out.indexOf('dart pub publish --force');
        final prePublishSection = out.substring(
          prePublishIndex,
          postPublishIndex,
        );
        expect(
          prePublishSection,
          isNot(contains('--enforce-lockfile')),
          reason: 'the pre-publish gate must not enforce a lock (issue #325)',
        );
        expect(
          prePublishSection,
          contains('dart pub get'),
          reason: 'the pre-publish gate resolves per package',
        );
        expect(
          out.substring(postPublishIndex),
          contains('--enforce-lockfile'),
          reason: 'the post-publish phase runs the enforce-lockfile gate',
        );

        // The gate must abort the release BEFORE anything is published: its
        // planned steps precede the first `dart pub publish --force`.
        expect(publishIndex, isNonNegative, reason: out);
        expect(
          prePublishIndex,
          isNonNegative,
          reason: 'the gate must run before the publish step',
        );
        expect(
          prePublishIndex < publishIndex,
          isTrue,
          reason:
              'the pre-publish gate must be planned before the first publish',
        );
        expect(
          postPublishIndex > publishIndex,
          isTrue,
          reason: 'the post-publish phase must be planned after publishing',
        );
      },
    );

    test('publish.sh invokes the gate before publishing or pushing', () {
      final script = _read('scripts/publish.sh');

      // The gate is a defined step that the main flow actually calls.
      expect(script, contains('pre_publish_gate'));

      final callIndex = script.indexOf('\npre_publish_gate\n');
      final publishIndex = script.indexOf('dart pub publish --force');
      final pushIndex = script.indexOf('git push origin');

      expect(callIndex, isNonNegative, reason: 'pre_publish_gate is invoked');
      expect(publishIndex, isNonNegative, reason: 'publish step present');
      expect(pushIndex, isNonNegative, reason: 'push step present');
      expect(
        callIndex < publishIndex,
        isTrue,
        reason: 'pre_publish_gate must be invoked before the publish step',
      );
      expect(
        callIndex < pushIndex,
        isTrue,
        reason: 'pre_publish_gate must be invoked before the push step',
      );
    });
  });
}
