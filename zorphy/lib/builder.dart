import 'package:build/build.dart';

import 'src/shared_part_builder.dart';

/// Creates the build_runner builder for Zorphy code generation.
///
/// Since zorphy 3.0.0 this returns a shared-part builder: one colocated
/// `<library>.zorphy.dart` per library (issue #309), written as a plain
/// `build_to: source` output (the v2 shape, carrying the v3 content). It is
/// deliberately not build_runner's `adds_to_library` shared part, which
/// build_runner forces under its reserved `_br_/` tree.
///
Builder zorphyBuilder(BuilderOptions options) {
  if (options.config.isNotEmpty) {
    final names = options.config.keys.join(', ');
    throw ArgumentError.value(
      options.config,
      'options',
      'Unsupported zorphy builder options: $names',
    );
  }
  return zorphySharedPartBuilder(options);
}
