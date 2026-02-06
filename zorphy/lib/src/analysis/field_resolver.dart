import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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

    // Recursively add fields from class and its supertypes
    void addFields(ClassElement elem) {
      var elemName = elem.name ?? "";
      if (processedTypes.contains(elemName)) return;
      processedTypes.add(elemName);

      // Add fields from all supertypes
      fields.addAll(
        helpers.getAllFields(
          elem.allSupertypes.whereType<InterfaceType>().toList(),
          elem,
        ).where((x) => x.name != "hashCode" && x.name != "runtimeType"),
      );

      // Recursively add fields from annotated supertypes
      for (var supertype in elem.allSupertypes) {
        var supertypeName = supertype.element.name ?? "";
        if (allAnnotatedClasses.containsKey(supertypeName)) {
          addFields(allAnnotatedClasses[supertypeName]!);
        }
      }
    }

    addFields(classElement);
    return fields.toSet().toList();
  }
}
