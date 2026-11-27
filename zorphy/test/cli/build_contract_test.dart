import 'dart:io';

import 'package:build/build.dart';
import 'package:test/test.dart';
import 'package:zorphy/builder.dart';

void main() {
  test('empty builder options construct the shared-part builder', () {
    expect(zorphyBuilder(BuilderOptions(const {})), isA<Builder>());
  });

  test('unsupported builder options fail instead of being ignored', () {
    expect(
      () => zorphyBuilder(
        BuilderOptions(const {
          'plugins': ['package:example/plugin.dart'],
        }),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('the public barrel does not export the dead generator', () {
    final source = File('lib/zorphy.dart').readAsStringSync();
    expect(source, isNot(contains('zorphy_generator.dart')));
  });

  test('the CLI rejects the removed dry-run flag', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'bin/zorphy_cli.dart',
      'build',
      '--dry-run',
    ]);
    final output = '${result.stdout}${result.stderr}';
    expect(result.exitCode, isNot(0));
    expect(output, contains('dry-run'));
  });
}
