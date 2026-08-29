/// GYM warmup rep #2 — self-build the zorphy package (codegen + compile).
///
/// zorphy is a codegen package, so "build" means running its own
/// source-generation over the committed sources (`build_runner build`)
/// and proving the package's own `lib/` compiles with zero analyzer
/// errors afterwards. The example/ tree carries pre-existing issues on a
/// fresh checkout (missing optional deps) and is deliberately out of the
/// rep's scope — the rep gates on the package surface an operator uses.
///
/// Run from the zorphy package root: `dart run .gym/warmup/02-build.dart`
///
/// A mis-fire (unexpected outcome, not a clean failure) is a DROP CARD —
/// see github.com/arrrrny/drop-card.
library;

import 'dart:io';

/// Entry point for warmup rep #2.
Future<void> main() async {
  final build = await Process.run('dart', [
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
  ]);
  if (build.exitCode != 0) {
    stderr.writeln(
      'REP FAIL: 02-build — build_runner exited ${build.exitCode}',
    );
    stderr.writeln(build.stdout);
    stderr.writeln(build.stderr);
    exit(build.exitCode == 0 ? 1 : build.exitCode);
  }

  final analyze = await Process.run('dart', ['analyze', 'lib']);
  final out = '${analyze.stdout as String}${analyze.stderr as String}';
  if (out.contains(' error - ')) {
    stderr.writeln(
      'REP FAIL: 02-build — self-build completed but `dart analyze lib` '
      'reports errors (the package does not compile).',
    );
    stderr.writeln(out);
    exit(1);
  }

  stdout.writeln('REP OK: 02-build — codegen ran and lib/ compiles clean.');
}
