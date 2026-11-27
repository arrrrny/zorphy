import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// The repository root: this test runs with the `zorphy` package as cwd (the
/// documented `dart test` invocation) and the package sits directly under the
/// root. Running from the repo root instead would resolve the wrong root.
final Directory _packageDir = Directory('${Directory.current.path}/..');
final String _repoRoot = _packageDir.resolveSymbolicLinksSync();

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

/// Runs [command] in [root], returning the trimmed stdout.
String _run(Directory root, List<String> command) {
  final result = Process.runSync(
    command.first,
    command.sublist(1),
    workingDirectory: root.path,
  );
  if (result.exitCode != 0) {
    fail(
      'command failed (${result.exitCode}): ${command.join(' ')}\n'
      '${result.stdout}\n${result.stderr}',
    );
  }
  return (result.stdout as String).trim();
}

void _git(Directory root, List<String> args) => _run(root, ['git', ...args]);

/// Runs [command] in [root] feeding [stdin] to the process, returning the
/// combined stdout+stderr. Used for the pre-push gate, which reads the pushed
/// refs from stdin.
Future<String> _runWithStdin(
  Directory root,
  List<String> command,
  String stdin, {
  Map<String, String>? env,
  Set<String> unset = const {},
}) async {
  final childEnvironment = {...Platform.environment, ...?env};
  for (final key in unset) {
    childEnvironment.remove(key);
  }
  final process = await Process.start(
    command.first,
    command.sublist(1),
    workingDirectory: root.path,
    environment: childEnvironment,
    includeParentEnvironment: false,
  );
  process.stdin.write(stdin);
  await process.stdin.close();
  final out = await process.stdout.transform(utf8.decoder).join();
  final err = await process.stderr.transform(utf8.decoder).join();
  final code = await process.exitCode;
  return 'exit=$code\n$out$err';
}

/// A synthetic merged-PR record as `gh pr list --json` would emit it.
String _pr(int number, String oid, String base) => jsonEncode({
  'number': number,
  'title': 'PR #$number',
  'baseRefName': base,
  'mergeCommit': {'oid': oid},
});

/// A merged-PR record that also carries a `mergedAt` timestamp, so the
/// `SWEEP_DAYS` window has data to filter on (issue #322).
String _prAt(int number, String oid, String base, String mergedAt) =>
    jsonEncode({
      'number': number,
      'title': 'PR #$number',
      'baseRefName': base,
      'mergedAt': mergedAt,
      'mergeCommit': {'oid': oid},
    });

/// A temp bin directory holding a `gh` that always fails, returned as a PATH
/// prefix that activates it — simulates `gh` being unavailable (network/auth
/// error) so the fail-closed behaviour can be exercised deterministically.
String _failingGhPath(Directory root) {
  final bin = Directory('${root.path}/fakebin')..createSync(recursive: true);
  final gh = File('${bin.path}/gh')..writeAsStringSync('#!/bin/sh\nexit 1\n');
  Process.runSync('chmod', ['+x', gh.path]);
  return '${bin.path}:${Platform.environment['PATH'] ?? ''}';
}

void main() {
  group('executable hook bits (issue #322)', () {
    test('pre-push hook and install_hooks.sh are executable', () {
      for (final rel in [
        'scripts/git-hooks/pre-push',
        'scripts/install_hooks.sh',
      ]) {
        final mode = File('$_repoRoot/$rel').statSync().mode;
        expect(
          mode & 0x49,
          isNot(0),
          reason: '$rel is not executable (mode ${mode.toRadixString(8)})',
        );
      }
    });
  });

  group('check_stacked_pr_integrity.sh', () {
    late Directory root;
    late String base; // a commit on master that is NOT the merge commit
    late String mergeOid; // the merged PR's merge commit
    late String stackTip; // old stack tip that contains mergeOid
    late String rebased; // new tip after a rebase that drops mergeOid

    setUp(() {
      root = Directory.systemTemp.createTempSync('zorphy_stacked_integrity_');
      _writeLayout(root, {
        'scripts/check_stacked_pr_integrity.sh': _read(
          'scripts/check_stacked_pr_integrity.sh',
        ),
      });
      _git(root, ['init', '-q', '-b', 'master']);
      _git(root, ['config', 'user.email', 'test@example.com']);
      _git(root, ['config', 'user.name', 'Test']);

      File('${root.path}/f.txt').writeAsStringSync('base\n');
      _git(root, ['add', '-A']);
      _git(root, ['commit', '-q', '-m', 'base']);
      base = _run(root, ['git', 'rev-parse', 'HEAD']);

      // A PR merged into the stack base: merge commit on the stack branch.
      _git(root, ['checkout', '-q', '-b', 'stack']);
      File('${root.path}/f.txt').writeAsStringSync('feature\n');
      _git(root, ['add', '-A']);
      _git(root, ['commit', '-q', '-m', 'feature #7']);
      mergeOid = _run(root, ['git', 'rev-parse', 'HEAD']);
      stackTip = mergeOid;

      // The force-push (rebase) that drops the merge commit: a new commit on
      // master that does NOT contain mergeOid in its history.
      _git(root, ['checkout', '-q', 'master']);
      File('${root.path}/g.txt').writeAsStringSync('other\n');
      _git(root, ['add', '-A']);
      _git(root, ['commit', '-q', '-m', 'unrelated master work']);
      rebased = _run(root, ['git', 'rev-parse', 'HEAD']);
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('refuses a force-push that orphans a merged PR', () async {
      // stdin: <local_ref> <local_sha> <remote_ref> <remote_sha>
      final stdin = 'refs/heads/stack $rebased refs/heads/stack $stackTip\n';
      final prs = '${_pr(7, mergeOid, 'master')}\n';

      final out = await _runWithStdin(
        root,
        ['bash', 'scripts/check_stacked_pr_integrity.sh'],
        stdin,
        env: {'GH_PR_LIST_JSON': prs},
      );

      expect(out, contains('exit=1'), reason: out);
      expect(out, contains('#7'));
      expect(out, contains('STACK_REBASE_OK'));
    });

    test('passes a normal fast-forward push', () async {
      final stdin = 'refs/heads/master $rebased refs/heads/master $base\n';
      // Offline empty inventory: a successful lookup with no merged PRs. The
      // gate now fails closed on a real gh error, so the happy path supplies
      // the explicit offline source instead of relying on gh being absent.
      final out = await _runWithStdin(
        root,
        ['bash', 'scripts/check_stacked_pr_integrity.sh'],
        stdin,
        env: {'GH_PR_LIST_JSON': ''},
      );

      expect(out, contains('exit=0'), reason: out);
    });

    test('refuses a push when gh is unavailable and no offline inventory is set '
        '(fail closed)', () async {
      // A real force-push on stdin, gh stubbed to fail, no GH_PR_LIST_JSON: the
      // lookup error must NOT be read as an empty inventory that allows the
      // push (the #322 fail-open bug).
      final stdin = 'refs/heads/stack $rebased refs/heads/stack $stackTip\n';
      final out = await _runWithStdin(
        root,
        ['bash', 'scripts/check_stacked_pr_integrity.sh'],
        stdin,
        env: {'PATH': _failingGhPath(root)},
        unset: {'GH_PR_LIST_JSON'},
      );

      expect(out, contains('exit=1'), reason: out);
    });

    test('allows the orphaning push with STACK_REBASE_OK=1', () async {
      final stdin = 'refs/heads/stack $rebased refs/heads/stack $stackTip\n';
      final prs = '${_pr(7, mergeOid, 'master')}\n';
      final out = await _runWithStdin(
        root,
        ['bash', 'scripts/check_stacked_pr_integrity.sh'],
        stdin,
        env: {'STACK_REBASE_OK': '1', 'GH_PR_LIST_JSON': prs},
      );

      expect(out, contains('exit=0'), reason: out);
    });
  });

  group('sweep_merged_content.sh', () {
    late Directory root;
    late String onMaster;
    late String orphaned;

    setUp(() {
      root = Directory.systemTemp.createTempSync('zorphy_merged_sweep_');
      _writeLayout(root, {
        'scripts/sweep_merged_content.sh': _read(
          'scripts/sweep_merged_content.sh',
        ),
      });
      _git(root, ['init', '-q', '-b', 'master']);
      _git(root, ['config', 'user.email', 'test@example.com']);
      _git(root, ['config', 'user.name', 'Test']);

      File('${root.path}/f.txt').writeAsStringSync('base\n');
      _git(root, ['add', '-A']);
      _git(root, ['commit', '-q', '-m', 'base']);

      // A healthy merged PR whose merge commit IS on master.
      File('${root.path}/f.txt').writeAsStringSync('landed\n');
      _git(root, ['add', '-A']);
      _git(root, ['commit', '-q', '-m', 'landed #1']);
      onMaster = _run(root, ['git', 'rev-parse', 'HEAD']);

      // An orphaned merge commit that never reached master.
      _git(root, ['checkout', '-q', '-b', 'lost']);
      File('${root.path}/h.txt').writeAsStringSync('lost\n');
      _git(root, ['add', '-A']);
      _git(root, ['commit', '-q', '-m', 'lost #2']);
      orphaned = _run(root, ['git', 'rev-parse', 'HEAD']);
      _git(root, ['checkout', '-q', 'master']);
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('reports an orphaned merge and exits non-zero', () async {
      final prs = [
        _pr(1, onMaster, 'master'),
        _pr(2, orphaned, 'master'),
      ].join('\n');

      final result = await Process.run(
        'bash',
        ['scripts/sweep_merged_content.sh'],
        workingDirectory: root.path,
        environment: {...Platform.environment, 'GH_PR_LIST_JSON': prs},
      );

      final out = '${result.stdout}${result.stderr}';
      expect(result.exitCode, 1, reason: out);
      expect(out, contains('#2'));
      expect(
        out,
        isNot(contains('orphaned merge: #1')),
        reason: 'the healthy PR must not be reported',
      );
    });

    test('passes when every merged PR is on master', () async {
      final prs = '${_pr(1, onMaster, 'master')}\n';

      final result = await Process.run(
        'bash',
        ['scripts/sweep_merged_content.sh'],
        workingDirectory: root.path,
        environment: {...Platform.environment, 'GH_PR_LIST_JSON': prs},
      );

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(result.stdout, contains('OK'));
    });

    test('fails closed when gh is unavailable and no offline inventory is set', () async {
      // gh stubbed to fail, no GH_PR_LIST_JSON: the lookup error must fail the
      // sweep (non-zero) instead of being read as "no merged PRs — OK" (the
      // #322 fail-open bug that silently skipped the release backstop).
      final environment = {
        ...Platform.environment,
        'PATH': _failingGhPath(root),
      }..remove('GH_PR_LIST_JSON');
      final result = await Process.run(
        'bash',
        ['scripts/sweep_merged_content.sh'],
        workingDirectory: root.path,
        environment: environment,
        includeParentEnvironment: false,
      );

      expect(
        result.exitCode,
        isNot(0),
        reason: 'a gh lookup failure must fail the sweep, not pass it',
      );
    });

    test(
      'keeps orphan issue identity when only origin/master exists',
      () async {
        final bin = Directory('${root.path}/fakebin')
          ..createSync(recursive: true);
        final gh = File('${bin.path}/gh')
          ..writeAsStringSync(r'''#!/bin/sh
if [ "$1" = "pr" ] && [ "$2" = "list" ]; then
  cat "$GH_INVENTORY_FILE"
elif [ "$1" = "issue" ] && [ "$2" = "list" ]; then
  exit 0
elif [ "$1" = "issue" ] && [ "$2" = "create" ]; then
  printf '%s\n' "$@" > "$GH_CAPTURE_FILE"
fi
''');
        Process.runSync('chmod', ['+x', gh.path]);

        final inventory = File('${root.path}/inventory.jsonl')
          ..writeAsStringSync('${_pr(2, orphaned, 'master')}\n');
        final capture = File('${root.path}/issue-create.txt');
        _git(root, ['update-ref', 'refs/remotes/origin/master', 'master']);
        _git(root, ['checkout', '-q', '--detach', 'master']);
        _git(root, ['update-ref', '-d', 'refs/heads/master']);

        final environment = {
          ...Platform.environment,
          'PATH': '${bin.path}:${Platform.environment['PATH'] ?? ''}',
          'GH_INVENTORY_FILE': inventory.path,
          'GH_CAPTURE_FILE': capture.path,
        }..remove('GH_PR_LIST_JSON');
        final result = await Process.run(
          'bash',
          ['scripts/sweep_merged_content.sh'],
          workingDirectory: root.path,
          environment: environment,
          includeParentEnvironment: false,
        );

        final out = '${result.stdout}${result.stderr}';
        expect(result.exitCode, 1, reason: out);
        final args = capture.readAsStringSync();
        expect(args, contains('orphaned merge: #2 content not on master'));
        expect(args, contains('not an ancestor of `master`'));
        expect(args, isNot(contains('origin/master')));
      },
    );

    test('SWEEP_DAYS controls the merged-PR window', () async {
      final fresh = DateTime.now().toIso8601String();
      final old = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String();
      final prs = [
        _prAt(1, onMaster, 'master', fresh),
        _prAt(2, orphaned, 'master', old),
      ].join('\n');

      // A 1-day window excludes the 30-day-old orphan (#2): nothing to report.
      final narrow = await Process.run(
        'bash',
        ['scripts/sweep_merged_content.sh'],
        workingDirectory: root.path,
        environment: {
          ...Platform.environment,
          'GH_PR_LIST_JSON': prs,
          'SWEEP_DAYS': '1',
        },
      );
      final narrowOut = '${narrow.stdout}${narrow.stderr}';
      expect(narrow.exitCode, 0, reason: narrowOut);
      expect(
        narrowOut,
        isNot(contains('orphaned merge: #2')),
        reason: 'SWEEP_DAYS=1 must exclude the older merged PR',
      );

      // A 90-day window includes it again: the orphan is reported, exit 1.
      final wide = await Process.run(
        'bash',
        ['scripts/sweep_merged_content.sh'],
        workingDirectory: root.path,
        environment: {
          ...Platform.environment,
          'GH_PR_LIST_JSON': prs,
          'SWEEP_DAYS': '90',
        },
      );
      final wideOut = '${wide.stdout}${wide.stderr}';
      expect(wide.exitCode, 1, reason: wideOut);
      expect(wideOut, contains('orphaned merge: #2'));
    });
  });
}
