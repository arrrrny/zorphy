import 'dart:io';

import 'package:test/test.dart';

/// Regression gate for issue #325: the clean-checkout release gate must be
/// split into a PRE-PUBLISH gate and a POST-PUBLISH lock verification.
///
/// `3.0.0-dev.5` could not be released because `publish.sh` ran
/// `dart pub get --enforce-lockfile` against the release commit BEFORE
/// publishing. At that point the release commit's internal constraints already
/// point at the unpublished version (`^3.0.0-dev.5`) while the committed
/// lockfiles still pin the previous line (`dev.4`) — and they CANNOT pin
/// `dev.5` because it does not exist on pub.dev yet. The lock step is
/// unresolvable pre-publish, forever, so the gate can never pass for a real
/// version bump. `dev.4` itself pre-dates the gate, which is why it shipped
/// base-red and needed the #308 manual lock repair.
///
/// The fix: the pre-publish gate proves the constraints are *satisfiable*
/// (resolve-allowed `dart pub get`, never `--enforce-lockfile`), and a new
/// post-publish phase — run after `dart pub publish` succeeds, when the new
/// version exists — regenerates the locks with `--enforce-lockfile`, commits
/// the lock refresh, and pushes it as the release's base-green tip. That is
/// exactly what #308 did by hand after dev.4.
///
/// These tests pin that contract into `publish.sh` by reading the script text
/// (the same structural-assertion style as `release_gate_test.dart`): they fail
/// on a tree whose pre-publish gate enforces a lock against an unpublished
/// version, and pass once the two phases are split.

/// The repository root: this test runs with the `zorphy` package as cwd (the
/// documented `dart test` invocation) and the package sits directly under it.
final String _repoRoot = Directory(
  '${Directory.current.path}/..',
).resolveSymbolicLinksSync();

String _read(String relative) =>
    File('$_repoRoot/$relative').readAsStringSync();

/// Extracts a bash function body: from the `<name>() {` line to the next line
/// that is a lone `}` at column 0 (the closing brace of a top-level function in
/// `publish.sh`). Returns null when the function is not defined.
String? _functionBody(String script, String name) {
  final lines = script.split('\n');
  final start = lines.indexWhere(
    (l) => RegExp('^\\s*${RegExp.escape(name)}\\s*\\(\\)\\s*\\{').hasMatch(l),
  );
  if (start < 0) return null;
  final body = <String>[];
  for (var i = start; i < lines.length; i++) {
    if (i > start && lines[i] == '}') break;
    body.add(lines[i]);
  }
  return body.join('\n');
}

/// The pre-publish gate body, tolerating the pre-fix name so the reproduction
/// fails for the reported reason (the gate enforces a lock pre-publish) rather
/// than merely because a symbol was renamed.
String? _prePublishBody(String script) =>
    _functionBody(script, 'pre_publish_gate') ??
    _functionBody(script, 'release_gate');

void main() {
  group('two-phase release gate (issue #325)', () {
    test('pre-publish gate never runs --enforce-lockfile', () {
      final script = _read('scripts/publish.sh');
      final pre = _prePublishBody(script);

      expect(pre, isNotNull, reason: 'a pre-publish gate function must exist');
      expect(
        pre,
        isNot(contains('--enforce-lockfile')),
        reason:
            'the pre-publish gate must not enforce a lock against an '
            'unpublished version (issue #325)',
      );
      // It still proves the constraints resolve — against published versions.
      expect(
        pre,
        contains('dart pub get'),
        reason: 'the pre-publish gate resolves (resolve-allowed) per package',
      );
    });

    test('post-publish phase regenerates and enforces the locks', () {
      final script = _read('scripts/publish.sh');
      final post = _functionBody(script, 'post_publish_verify');

      expect(
        post,
        isNotNull,
        reason: 'a post_publish_verify function must exist',
      );
      expect(
        post,
        contains('--enforce-lockfile'),
        reason: 'the post-publish phase runs the enforce-lockfile gate',
      );
      expect(
        post,
        contains('commit -m'),
        reason: 'the post-publish phase commits the lock refresh',
      );
      expect(
        post,
        contains('push origin'),
        reason: 'the post-publish phase pushes the base-green lock commit',
      );
    });

    test('publish.sh invokes the post-publish phase after publishing', () {
      final script = _read('scripts/publish.sh');

      // The invocation is a bare `post_publish_verify` line, distinct from the
      // `post_publish_verify() {` definition that appears earlier in the file.
      final callIndex = script.indexOf('\npost_publish_verify\n');
      final publishIndex = script.indexOf('dart pub publish --force');
      final tagIndex = script.indexOf('git tag -a');

      expect(
        callIndex,
        isNonNegative,
        reason: 'post_publish_verify is invoked',
      );
      expect(publishIndex, isNonNegative, reason: 'publish step present');
      expect(tagIndex, isNonNegative, reason: 'tag step present');
      expect(
        callIndex > publishIndex,
        isTrue,
        reason: 'post_publish_verify must run AFTER the publish step',
      );
      expect(
        callIndex < tagIndex,
        isTrue,
        reason: 'post_publish_verify must run BEFORE the tag is created',
      );
    });

    test('internal constraint bump is committed in the post-publish phase', () {
      final script = _read('scripts/publish.sh');
      final pre = _prePublishBody(script);
      final post = _functionBody(script, 'post_publish_verify');

      expect(
        pre,
        contains('check_internal_constraints.sh'),
        reason:
            'the pre-publish gate checks admission against the published line',
      );
      expect(
        post,
        contains(r'zorphy_annotation: ^$VERSION'),
        reason: 'the ^<version> bump is applied after publishing',
      );
      expect(
        post,
        contains(
          r'chore: refresh lockfiles + internal constraints for v$VERSION',
        ),
        reason: 'the bump is committed together with the lock refresh',
      );
      expect(
        pre,
        isNot(contains('refresh lockfiles + internal constraints')),
        reason: 'the bump is not committed by the pre-publish gate',
      );
    });

    test(
      'post-publish carries the verified locks and cleans every override',
      () {
        final post = _functionBody(
          _read('scripts/publish.sh'),
          'post_publish_verify',
        );

        expect(
          post,
          contains('pubspec.lock'),
          reason: 'verified locks are copied',
        );
        expect(
          post,
          contains('cp '),
          reason: 'the verified lock is copied, not re-resolved',
        );
        expect(
          post,
          contains('zorphy/example'),
          reason: 'the example override is cleaned too',
        );
        expect(
          post,
          contains('No lock/constraint changes to commit'),
          reason: 'a no-op commit cannot abort the release after publishing',
        );
      },
    );

    test('--dry-run prints the two-phase plan', () async {
      final root = Directory.systemTemp.createTempSync('zorphy_two_phase_');
      try {
        for (final entry in {
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
        }.entries) {
          File('${root.path}/${entry.key}')
            ..createSync(recursive: true)
            ..writeAsStringSync(entry.value);
        }

        final result = await Process.run('bash', [
          'scripts/publish.sh',
          '9.9.9-dev.1',
          'two phase probe',
          '--dry-run',
        ], workingDirectory: root.path);
        final out = '${result.stdout}\n${result.stderr}';

        expect(result.exitCode, 0, reason: out);
        expect(out, contains('Pre-publish gate'));
        expect(out, contains('post-publish verification'));

        // The post-publish phase is planned after the first publish step.
        final postIndex = out.indexOf('Running post-publish verification');
        final publishIndex = out.indexOf('dart pub publish --force');
        expect(postIndex, isNonNegative, reason: out);
        expect(publishIndex, isNonNegative, reason: out);
        expect(
          postIndex > publishIndex,
          isTrue,
          reason: 'the post-publish phase must be planned after publishing',
        );
      } finally {
        root.deleteSync(recursive: true);
      }
    });
  });

  group('internal-constraint admission check (issue #325)', () {
    late Directory root;

    Future<ProcessResult> git(List<String> args) => Process.run('git', [
      '-C',
      root.path,
      ...args,
    ], workingDirectory: root.path);

    Future<void> writeConstraint(String constraint) async {
      for (final pkg in ['zorphy', 'zorphy_migrator']) {
        File('${root.path}/$pkg/pubspec.yaml').writeAsStringSync(
          'name: $pkg\n'
          'version: 3.0.0-dev.5\n'
          'dependencies:\n'
          '  zorphy_annotation: $constraint\n',
        );
      }
    }

    Future<ProcessResult> check(String constraint) async {
      await writeConstraint(constraint);
      return Process.run('bash', [
        'scripts/check_internal_constraints.sh',
        '3.0.0-dev.5',
      ], workingDirectory: root.path);
    }

    setUp(() async {
      root = Directory.systemTemp.createTempSync('zorphy_constraint_check_');
      Directory('${root.path}/scripts').createSync(recursive: true);
      for (final pkg in ['zorphy', 'zorphy_migrator']) {
        Directory('${root.path}/$pkg').createSync(recursive: true);
      }
      File(
        '${root.path}/scripts/check_internal_constraints.sh',
      ).writeAsStringSync(_read('scripts/check_internal_constraints.sh'));

      await Process.run('git', ['init', '-q'], workingDirectory: root.path);
      await git([
        '-c',
        'user.name=test',
        '-c',
        'user.email=test@example.com',
        'commit',
        '--allow-empty',
        '-qm',
        'init',
      ]);
      await git(['tag', 'annotation-v3.0.0-dev.4']);
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('accepts the previously published caret constraint', () async {
      final result = await check('^3.0.0-dev.4');
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        result.stdout,
        contains('previously published version 3.0.0-dev.4'),
      );
    });

    test('strips the constraint prefix before extracting the base', () async {
      final result = await check('>=3.0.0-dev.4');
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });

    test('rejects a constraint on a different numeric base', () async {
      final result = await check('^4.0.0-dev.4');
      expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
      expect(
        result.stdout,
        contains('not on the previously published base line'),
      );
    });

    test('rejects a constraint that excludes the published version', () async {
      final result = await check('^3.0.0-dev.5');
      expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
      expect(
        result.stdout,
        contains('excludes the previously published version'),
      );
    });
  });
}
