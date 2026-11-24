/// Emission pipeline — converts [Spec] objects to formatted Dart source.
///
/// This is the code_builder foundation for Zorphy v2.
/// Generators produce [Spec] objects (or use the default adapter that
/// wraps string output), which are then emitted through
/// [ZorphyEmitter].
library;

export 'boundary_codec_emitter.dart';
export 'emitter.dart';
export 'polymorphic_class_emitter.dart';
