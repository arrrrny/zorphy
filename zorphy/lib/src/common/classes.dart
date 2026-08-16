import 'NameType.dart';

class Interface {
  final String interfaceName;
  final List<NameType> typeParams;
  final List<NameType> fields;

  /// If true the subtype has been explicitly declared in the Zorphy annotation
  final bool isExplicitSubType;

  /// If true the interface is a sealed class (starts with $$)
  final bool isSealed;

  /// If true the interface has hidePublicConstructor: true
  final bool hidePublicConstructor;

  /// Custom wire value for polymorphic JSON dispatch.
  /// When null, [interfaceName] (stripped of $ prefix) is used.
  final String? wireValue;

  /// Creates an interface descriptor from generic names and bounds.
  Interface(
    this.interfaceName,
    List<String?> genericExtends,
    List<String?> genericName,
    this.fields, [
    this.isExplicitSubType = false,
    this.isSealed = false,
    this.hidePublicConstructor = false,
    this.wireValue,
  ]) : assert(
         genericExtends.length == genericName.length,
         "typeArgs must have same length as typeParams",
       ),
       typeParams = List.generate(
         genericName.length,
         (i) => NameType(genericName[i] ?? "", genericExtends[i] ?? ""),
       ) {}

  /// Creates an interface descriptor from prebuilt generics.
  Interface.fromGenerics(
    this.interfaceName,
    this.typeParams,
    this.fields, [
    this.isExplicitSubType = false,
    this.isSealed = false,
    this.hidePublicConstructor = false,
    this.wireValue,
  ]);

  /// Returns a compact string representation of the interface.
  toString() =>
      "${this.interfaceName.toString()}|${this.typeParams.toString()}|${this.fields.toString()}";
}

class InterfaceWithComment extends Interface {
  final String? comment;

  /// Creates an interface descriptor with an optional comment.
  InterfaceWithComment(
    String type,
    List<String?> typeArgsTypes,
    List<String?> typeParamsNames,
    List<NameType> fields, {
    this.comment,
    bool isSealed = false,
    bool hidePublicConstructor = false,
  }) : super(
         type,
         typeArgsTypes.map((e) => e ?? "").toList(),
         typeParamsNames.map((e) => e ?? "").toList(),
         fields,
         false,
         isSealed,
         hidePublicConstructor,
       );

  /// Returns a compact string representation of the interface.
  toString() =>
      "${this.interfaceName.toString()}|${this.typeParams.toString()}|${this.fields.toString()}";
}

class ClassDef {
  final bool isAbstract;
  final String name;
  final List<NameTypeClassComment> fields;
  final List<GenericsNameType> generics;
  final List<String> baseTypes;

  /// Creates a class definition descriptor.
  ClassDef(
    this.isAbstract,
    this.name,
    this.fields,
    this.generics,
    this.baseTypes,
  );
}

class GenericsNameType {
  final String name;
  final String? type;

  /// Creates a generic parameter descriptor.
  GenericsNameType(this.name, this.type);

  /// Returns a compact string representation of the generic.
  toString() => "${this.name}:${this.type}";
}

class MethodDetails<TMeta1> {
  final String? methodComment;
  final String methodName;
  final List<NameTypeClassCommentData<TMeta1>> paramsPositional;
  final List<NameTypeClassCommentData<TMeta1>> paramsNamed;
  final List<GenericsNameType> generics;
  final String returnType;

  /// Creates a method signature descriptor.
  MethodDetails(
    this.methodComment,
    this.methodName,
    this.paramsPositional,
    this.paramsNamed,
    this.generics,
    this.returnType,
  );
}
