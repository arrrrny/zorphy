import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

import 'package:zorphy/src/ZorphyGenerator.dart';

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
