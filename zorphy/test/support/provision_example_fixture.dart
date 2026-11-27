// Shared test support: provision the example package's generated build_runner
// fixture on demand (issue #287).
//
// The e2e suites under test/emission and test/generation read the REAL
// build_runner output (`example/lib/v3_archetypes/v3_archetypes.zorphy.dart`)
// rather than a hand-written stand-in. That part is `build_to: source` output
// and is gitignored (`*.zorphy.dart`, `*.g.dart`), so a fresh clone has no fixture and
// every suite's `setUpAll` used to `fail()` with "Run: cd example && dart run
// build_runner build" — a provisioning gap, not a code defect.
//
// `provisionExampleFixture` closes that gap: it builds the fixture once, on
// first use, so a bare `dart test -j 2` on a fresh clone is green. The build is
// serialized across the concurrent test processes `dart test -j 2` spawns (each
// suite runs in its own process and would otherwise race on the same example/
// tree) with an exclusive lock on a shared temp file, and the existence check is
// repeated under the lock so only the first waiter actually builds.

import 'dart:io';

import 'package:test/test.dart';

/// Path (relative to the `zorphy` package root, the test cwd) of the generated
/// fixture every e2e suite reads.
final String kExampleFixturePath =
    'example/lib/v3_archetypes/v3_archetypes.zorphy.dart';

/// Ensures [kExampleFixturePath] exists, building it via `build_runner` in
/// `example/` when it does not.
///
/// Returns the fixture body with any `part of` directive stripped, so the
/// fragment can be analyzed as a standalone library by the caller.
///
/// Fails the calling test with an actionable message when the build cannot
/// produce the fixture (build_runner error output is included).
String provisionExampleFixture() {
  final fixture = File(kExampleFixturePath);
  if (!fixture.existsSync()) {
    _buildExampleFixture();
  }
  if (!fixture.existsSync()) {
    fail(
      'Failed to provision generated fixture: $kExampleFixturePath\n'
      'Automatic `dart run build_runner build` did not produce it — see the '
      'build output above.',
    );
  }
  return fixture
      .readAsStringSync()
      .split('\n')
      .where((line) => !line.startsWith('part of'))
      .join('\n');
}

/// A process-wide lock path shared by every suite that provisions the fixture,
/// so concurrent `dart test -j 2` workers serialize the build instead of
/// racing on the same example/ output tree.
String get _lockPath =>
    '${Directory.systemTemp.path}/zorphy-issue287-example-build.lock';

void _buildExampleFixture() {
  final lockFile = File(_lockPath);
  lockFile.createSync(recursive: true);
  final lock = lockFile.openSync(mode: FileMode.write);
  try {
    lock.lockSync(FileLock.exclusive);
    // Re-check under the lock: another worker may have built it while we
    // waited, in which case there is nothing to do.
    if (File(kExampleFixturePath).existsSync()) return;

    final result = Process.runSync(
      'dart',
      const ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: 'example',
      runInShell: false,
    );
    if (result.exitCode != 0) {
      fail(
        'Automatic fixture build failed (exit ${result.exitCode}).\n'
        'stdout:\n${result.stdout}\n'
        'stderr:\n${result.stderr}',
      );
    }
  } finally {
    lock.unlockSync();
    lock.closeSync();
  }
}
