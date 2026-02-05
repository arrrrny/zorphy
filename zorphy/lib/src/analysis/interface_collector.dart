import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../common/NameType.dart';
import '../common/classes.dart';
import '../common/helpers.dart' as helpers;
import '../models/interface_metadata.dart';

/// Collects and analyzes interface hierarchy for a class
/// Handles inheritance, generics, and sealed class detection
class InterfaceCollector {
  /// Collect all interfaces that a class implements
  /// Returns InterfaceWithComment objects with full metadata
  static List<InterfaceMetadata> collect(
    ClassElement classElement,
    Map<String, ClassElement> allAnnotatedClasses,
  ) {
    final allInterfaces = <InterfaceType>[];
    final processedInterfaces = <String>{};
    final className = classElement.name ?? '';

    // Recursively collect interfaces
    void addInterface(InterfaceType interface) {
      var interfaceName = interface.element.name ?? "";
      // Skip Object and other built-in types
      if (interfaceName == "Object" || interfaceName == "Enum") return;
      if (processedInterfaces.contains(interfaceName)) return;
      processedInterfaces.add(interfaceName);
      allInterfaces.add(interface);

      // Recursively add parent interfaces
      for (var supertype in interface.element.allSupertypes) {
        addInterface(supertype);
      }
    }

    // Start collecting from all supertypes
    for (var supertype in classElement.allSupertypes) {
      addInterface(supertype);
    }

    // Convert to InterfaceMetadata with full analysis
    return allInterfaces.map((e) {
      var interfaceName = e.element.name ?? "";

      // Check if interface has @Zorphy annotation with nonSealed: true
      var isSealed = interfaceName.startsWith(r'$$');
      if (isSealed && e.element is ClassElement) {
        // Check if the interface has @Zorphy(nonSealed: true)
        var classElement = e.element as ClassElement;
        for (var annotation in classElement.metadata.annotations) {
          var annotationElement = annotation.element;
          if (annotationElement is ConstructorElement) {
            var enclosingElement = annotationElement.enclosingElement;
            if (enclosingElement.name == 'Zorphy') {
              try {
                var constantValue = annotation.computeConstantValue();
                var nonSealedField = constantValue?.getField('nonSealed');
                if (nonSealedField?.toBoolValue() == true) {
                  isSealed = false;
                }
              } catch (_) {}
            }
          }
        }
      }

      return InterfaceMetadata(
        interfaceName, // Don't strip $ prefix - interfaces should keep the $
        e.typeArguments
            .map((t) => helpers.typeToString(t, currentClassName: className))
            .toList(),
        e.element.typeParameters.map((x) => x.name ?? "").toList(),
        e.element.fields
            .map(
              (f) => NameType(
                f.name ?? "",
                helpers.typeToString(f.type, currentClassName: className),
              ),
            )
            .toList(),
        comment: e.element.documentationComment,
        isSealed: isSealed,
        hidePublicConstructor: false,
      );
    }).toList();
  }
}
