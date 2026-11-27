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
}) async {
  final process = await Process.start(
    command.first,
    command.sublist(1),
    workingDirectory: root.path,
    environment: {...Platform.environment, ...?env},
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

void main() {
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
      final out = await _runWithStdin(root, [
        'bash',
        'scripts/check_stacked_pr_integrity.sh',
      ], stdin);

      expect(out, contains('exit=0'), reason: out);
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
  });
}
