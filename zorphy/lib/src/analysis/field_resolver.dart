import 'package:analyzer/dart/element/element.dart';
import '../common/NameType.dart';
import '../common/helpers.dart' as helpers;

/// Resolves all fields for a class including inherited ones
/// Handles complex inheritance hierarchies with multiple interfaces
class FieldResolver {
  /// Resolve all fields (inherited + own) for a class
  /// Returns a distinct list of fields with duplicates removed
  static List<NameTypeClassComment> resolve(
    ClassElement classElement,
    Map<String, ClassElement> allAnnotatedClasses,
  ) {
    var fields = <NameTypeClassComment>[];
    var processedTypes = <String>{};

    // 1. Add fields from current class FIRST (highest priority)
    fields.addAll(
      helpers
          .getAllFields([], classElement)
          .where((x) => x.name != "hashCode" && x.name != "runtimeType"),
    );
    processedTypes.add(classElement.name ?? "");

    // 2. Add fields from all supertypes in proximity order
    for (var supertype in classElement.allSupertypes) {
      final element = supertype.element;
      var supertypeName = element.name ?? "";
      if (supertypeName == "Object" || processedTypes.contains(supertypeName)) {
        continue;
      }
      processedTypes.add(supertypeName);

      // Collect only OWN fields from the supertype to avoid redundant collection
      // helpers.getAllFields([], elem) does exactly this
      fields.addAll(
        helpers
            .getAllFields([], element)
            .where((x) => x.name != "hashCode" && x.name != "runtimeType"),
      );
    }

    // Deduplicate by field name (keep first occurrence = nearest child)
    final seen = <String>{};
    final distinct = <NameTypeClassComment>[];
    for (final field in fields) {
      if (!seen.contains(field.name)) {
        seen.add(field.name);
        distinct.add(field);
      }
    }

    return distinct;
  }
}
