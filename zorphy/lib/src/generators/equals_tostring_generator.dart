import '../common/helpers.dart' as helpers;
import '../models/class_metadata.dart';
import 'base_generator.dart';

/// Generates equals, hashCode, and toString methods
/// Wraps the existing getEqualsAndHashCode and getToString functions
class EqualsToStringGenerator extends ConcreteClassGenerator {
  EqualsToStringGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Generate equals and hashCode
    sb.writeln(helpers.getEqualsAndHashCode(metadata.allFields, className));

    // Generate toString
    sb.writeln(helpers.getToString(metadata.allFields, className));

    return sb.toString();
  }
}
