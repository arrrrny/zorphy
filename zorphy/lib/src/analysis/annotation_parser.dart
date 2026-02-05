import 'package:source_gen/source_gen.dart';

/// Parses @Zorphy annotation options
/// Extracts configuration from annotation constant reader
class AnnotationParser {
  /// Parse annotation and return options map
  /// For now, this is a simple placeholder - the actual options
  /// are read directly in the generators where needed
  static AnnotationOptions parse(ConstantReader annotation) {
    return AnnotationOptions(
      generateJson: annotation.read('generateJson').boolValue,
      explicitToJson: annotation.read('explicitToJson').boolValue,
      generateCopyWithFn: annotation.read('generateCopyWithFn').boolValue,
      generateCompareTo: annotation.read('generateCompareTo').boolValue,
      hidePublicConstructor: annotation.read('hidePublicConstructor').boolValue,
      nonSealed: annotation.read('nonSealed').boolValue,
    );
  }
}

/// Options extracted from @Zorphy annotation
class AnnotationOptions {
  final bool generateJson;
  final bool explicitToJson;
  final bool generateCopyWithFn;
  final bool generateCompareTo;
  final bool hidePublicConstructor;
  final bool nonSealed;

  const AnnotationOptions({
    required this.generateJson,
    required this.explicitToJson,
    required this.generateCopyWithFn,
    required this.generateCompareTo,
    required this.hidePublicConstructor,
    required this.nonSealed,
  });
}
