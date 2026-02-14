import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/zorphy_generator.dart';

/// Creates the build_runner builder for Zorphy code generation.
Builder zorphyBuilder(BuilderOptions options) {
  return PartBuilder(
    [ZorphyGenerator()],
    '.zorphy.dart',
    header: '''
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint
''',
  );
}
