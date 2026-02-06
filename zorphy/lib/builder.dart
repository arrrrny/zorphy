import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:zorphy/src/zorphy_generator_v2.dart';

Builder zorphyBuilder(BuilderOptions options) {
  return PartBuilder(
    [ZorphyGeneratorV2()],
    '.zorphy.dart',
    header: '''
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint
''',
  );
}
