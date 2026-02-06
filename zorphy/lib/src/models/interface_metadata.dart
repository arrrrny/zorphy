import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../common/NameType.dart';
import '../common/classes.dart';

/// Re-export Interface
export '../common/classes.dart' show Interface;

/// Extended interface metadata that includes the ClassElement
/// This wraps InterfaceWithComment and adds the element property
class InterfaceMetadata extends InterfaceWithComment {
  final ClassElement element;

  // Store type arguments separately for easier access
  final List<DartType> _typeArguments;

  InterfaceMetadata(
    String type,
    List<String?> typeArgsTypes,
    List<String?> typeParamsNames,
    List<NameType> fields, {
    String? comment,
    bool isSealed = false,
    bool hidePublicConstructor = false,
    required this.element,
    List<DartType>? typeArguments,
  }) : _typeArguments = typeArguments ?? [],
       super(
         type,
         typeArgsTypes,
         typeParamsNames,
         fields,
         comment: comment,
         isSealed: isSealed,
         hidePublicConstructor: hidePublicConstructor,
       );

  // Getter for type arguments
  List<DartType> get typeArguments => _typeArguments;

  // Factory to convert from InterfaceWithComment
  factory InterfaceMetadata.fromInterfaceWithComment(
    InterfaceWithComment iwc,
    ClassElement element, {
    List<DartType>? typeArguments,
  }) {
    return InterfaceMetadata(
      iwc.interfaceName,
      iwc.typeParams.map((tp) => tp.type).toList(),
      iwc.typeParams.map((tp) => tp.name).toList(),
      iwc.fields,
      comment: iwc.comment,
      isSealed: iwc.isSealed,
      hidePublicConstructor: iwc.hidePublicConstructor,
      element: element,
      typeArguments: typeArguments,
    );
  }

  toString() =>
      "${this.interfaceName.toString()}|${this.typeParams.toString()}|${this.fields.toString()}|element=${element.name}";
}
