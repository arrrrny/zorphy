import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/common/GeneratorForAnnotationX.dart';
import 'package:zorphy/src/factory_method.dart';
import 'package:zorphy/src/models/models.dart';
import 'package:zorphy/src/orchestrator.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

class ZorphyGeneratorV2 extends GeneratorForAnnotationX<Zorphy> {
  static final Map<String, ClassElement> _allAnnotatedClasses = {};
  static Map<String, ClassElement> get allAnnotatedClasses =>
      _allAnnotatedClasses;

  @override
  TypeChecker get typeChecker => const TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy',
  );

  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
    List<ClassElement> allClasses,
  ) {
    if (element is! ClassElement) {
      throw Exception("not a class");
    }

    var classElement = element;
    var className = classElement.name ?? "";
    _allAnnotatedClasses[className] = classElement;

    if (classElement.supertype?.element.name != "Object") {
      throw Exception("you must use implements, not extends");
    }

    // Collect factory methods
    var factoryMethods = _getFactoryMethods(classElement);

    // Get own fields (defined directly on this class, not inherited)
    var ownFields = classElement.fields
        .where((f) => f.name != "hashCode" && f.name != "runtimeType")
        .map((f) => f.name ?? "")
        .toSet();

    // Read configuration from annotation
    final config = GenerationConfig.zorphy(
      generateJson: annotation.read('generateJson').boolValue,
      explicitToJson: annotation.read('explicitToJson').boolValue,
      generateCopyWithFn: annotation.read('generateCopyWithFn').boolValue,
      generateCompareTo: annotation.read('generateCompareTo').boolValue,
      generatePatch: annotation.peek('generatePatch')?.boolValue ?? true,
      hidePublicConstructor: annotation.read('hidePublicConstructor').boolValue,
      factoryMethods: factoryMethods,
      ownFields: ownFields,
    );

    // Use the new orchestrator pipeline
    return Orchestrator.generate(
      classElement,
      annotation,
      _allAnnotatedClasses,
      config,
    );
  }

  List<FactoryMethodInfo> _getFactoryMethods(ClassElement element) {
    var factoryMethods = <FactoryMethodInfo>[];
    var className = element.name ?? "";

    for (var constructor in element.constructors) {
      var constructorName = constructor.name;
      if (constructor.isFactory &&
          constructorName != null &&
          constructorName.isNotEmpty) {
        var methodName = constructorName;
        var parameters = constructor.formalParameters.map((param) {
          var paramType = param.type.toString();

          // Handle self-referencing types
          if (paramType.contains('InvalidType') || paramType == 'dynamic') {
            var classNameTrimmed = className.replaceAll('\$', '');

            // Check if this is a self-reference to the current class
            if (param.type.element?.displayName == element.name ||
                param.type.element?.displayName == classNameTrimmed) {
              paramType = classNameTrimmed;
            } else {
              // For InvalidType, try to resolve from the source code
              paramType = 'dynamic';
            }
          }

          return FactoryParameterInfo(
            name: param.name ?? "",
            type: paramType,
            isRequired: param.isRequiredNamed || param.isRequiredPositional,
            isNamed: param.isNamed,
            hasDefaultValue: param.hasDefaultValue,
            defaultValue: param.defaultValueCode,
          );
        }).toList();

        factoryMethods.add(
          FactoryMethodInfo(
            name: methodName,
            parameters: parameters,
            bodyCode: "",
            className: className,
          ),
        );
      }
    }

    return factoryMethods;
  }
}
