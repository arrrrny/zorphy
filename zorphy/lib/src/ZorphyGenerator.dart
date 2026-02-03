import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/common/GeneratorForAnnotationX.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/classes.dart';
import 'package:zorphy/src/common/helpers.dart';
import 'package:zorphy/src/helpers.dart';
import 'package:zorphy/src/createZorphy.dart';
import 'package:zorphy/src/factory_method.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

class ZorphyGenerator extends GeneratorForAnnotationX<Zorphy> {
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
    var sb = StringBuffer();

    if (element is! ClassElement) {
      throw Exception("not a class");
    }

    var classElement = element;
    var className = classElement.name ?? "";
    _allAnnotatedClasses[className] = classElement;

    var hasConstConstructor = classElement.constructors.any((e) => e.isConst);
    var nonSealed = annotation.read('nonSealed').boolValue;
    var isAbstract = className.startsWith("\$\$") && !nonSealed;

    if (classElement.supertype?.element.name != "Object") {
      throw Exception("you must use implements, not extends");
    }

    // Collect factory methods
    var factoryMethods = getFactoryMethods(classElement);

    var docComment = classElement.documentationComment;

    var allInterfaces = <InterfaceType>[];
    var processedInterfaces = <String>{};

    void addInterface(InterfaceType interface) {
      var interfaceName = interface.element.name ?? "";
      // Skip Object and other built-in types
      if (interfaceName == "Object" || interfaceName == "Enum") return;
      if (processedInterfaces.contains(interfaceName)) return;
      processedInterfaces.add(interfaceName);
      allInterfaces.add(interface);

      for (var supertype in interface.element.allSupertypes) {
        addInterface(supertype);
      }
    }

    for (var supertype in classElement.allSupertypes) {
      addInterface(supertype);
    }

    var interfaces = allInterfaces.map((e) {
      var interfaceName = e.element.name ?? "";
      // Don't strip $ prefix - interfaces should keep the $ to reference abstract classes
      var implementedName = interfaceName;

      return InterfaceWithComment(
        implementedName,
        e.typeArguments.map(typeToString).toList(),
        e.element.typeParameters.map((x) => x.name ?? "").toList(),
        e.element.fields
            .map((f) => NameType(f.name ?? "", typeToString(f.type)))
            .toList(),
        comment: e.element.documentationComment,
        isSealed: interfaceName.startsWith("\$\$"),
        hidePublicConstructor: false,
      );
    }).toList();

    var allFields = getAllFieldsIncludingSubtypes(classElement);
    var allFieldsDistinct = getDistinctFields(allFields, interfaces);

    var classGenerics = classElement.typeParameters.map((e) {
      final bound = e.bound;
      return NameTypeClassComment(
        e.name ?? "",
        bound == null ? null : typeToString(bound),
        null,
      );
    }).toList();

    var typesExplicit = <Interface>[];
    if (!annotation.read('explicitSubTypes').isNull) {
      typesExplicit = annotation.read('explicitSubTypes').listValue.map((x) {
        var typeValue = x.toTypeValue();
        if (typeValue?.element is! ClassElement) {
          throw Exception("each type for the copywith def must all be classes");
        }

        var el = typeValue!.element as ClassElement;
        _allAnnotatedClasses[el.name ?? ""] = el;

        var fields = getAllFieldsIncludingSubtypes(el)
            .where((f) => f.name != "hashCode")
            .toList();
        var nameTypeFields =
            fields.map((f) => NameType(f.name, f.type ?? "")).toList();

        return Interface.fromGenerics(
          el.name ?? "",
          el.typeParameters.map((tp) {
            final bound = tp.bound;
            return NameType(
                tp.name ?? "", bound == null ? null : typeToString(bound));
          }).toList(),
          nameTypeFields,
          true,
        );
      }).toList();
    }

    var allValueTInterfaces = allInterfaces
        .map((e) {
          var interfaceName = e.element.name ?? "";
          var fields = getAllFieldsIncludingSubtypes(e.element as ClassElement)
              .where((f) => f.name != "hashCode")
              .toList();
          var nameTypeFields =
              fields.map((f) => NameType(f.name, f.type ?? "")).toList();
          return Interface.fromGenerics(
            interfaceName, // Keep the original interface name with $ prefix
            e.typeArguments.asMap().entries.map((entry) {
              final index = entry.key;
              final typeArg = entry.value;
              final paramName = e.element.typeParameters.length > index
                  ? e.element.typeParameters[index].name ??
                      "T" + index.toString()
                  : "T" + index.toString();
              return NameType(paramName, typeToString(typeArg));
            }).toList(),
            nameTypeFields,
            false,
            interfaceName.startsWith("\$\$"),
            false,
          );
        })
        .cast<Interface>()
        .toList();

    sb.writeln(
      createZorphy(
        isAbstract,
        allFieldsDistinct,
        className,
        docComment ?? "",
        interfaces,
        allValueTInterfaces,
        classGenerics,
        hasConstConstructor,
        annotation.read('generateJson').boolValue,
        annotation.read('hidePublicConstructor').boolValue,
        typesExplicit,
        nonSealed,
        annotation.read('explicitToJson').boolValue,
        annotation.read('generateCompareTo').boolValue,
        annotation.read('generateCopyWithFn').boolValue,
        factoryMethods,
        _allAnnotatedClasses,
      ),
    );

    return sb.toString();
  }

  List<NameTypeClassComment> getAllFieldsIncludingSubtypes(
      ClassElement element) {
    var fields = <NameTypeClassComment>[];
    var processedTypes = <String>{};

    void addFields(ClassElement elem) {
      var elemName = elem.name ?? "";
      if (processedTypes.contains(elemName)) return;
      processedTypes.add(elemName);

      fields.addAll(
        getAllFields(
          elem.allSupertypes.whereType<InterfaceType>().toList(),
          elem,
        ).where((x) => x.name != "hashCode" && x.name != "runtimeType"),
      );

      for (var supertype in elem.allSupertypes) {
        var supertypeName = supertype.element.name ?? "";
        if (_allAnnotatedClasses.containsKey(supertypeName)) {
          addFields(_allAnnotatedClasses[supertypeName]!);
        }
      }
    }

    addFields(element);
    return fields.toSet().toList();
  }

  List<FactoryMethodInfo> getFactoryMethods(ClassElement element) {
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
