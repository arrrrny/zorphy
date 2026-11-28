// ignore_for_file: experimental_member_use

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

String declaredTypeText(DartType type, Fragment fragment) {
  // Recover from source whenever an `InvalidType` appears ANYWHERE in the
  // type — not only at the top level. A cross-library union used as a type
  // argument (`List<AppFailure>`) has a valid outer type whose argument is
  // `InvalidType`; returning its display string would emit the invalid
  // argument name and produce code that does not compile (#351 review).
  if (!_containsInvalidType(type)) return type.getDisplayString();
  final library = fragment.libraryFragment;
  if (library == null) return type.getDisplayString();
  final source = library.source;
  final parsed = parseString(
    content: source.contents.data,
    path: source.uri.toString(),
    throwIfDiagnostics: false,
  );
  return _typeAt(parsed.unit, fragment.offset) ?? type.getDisplayString();
}

/// Whether [type] is, or transitively contains, an [InvalidType] — descending
/// through type arguments so a cross-library union used as an argument
/// (`List<AppFailure>`) is recovered from source too.
bool _containsInvalidType(DartType type) {
  if (type is InvalidType) return true;
  if (type is InterfaceType) {
    return type.typeArguments.any(_containsInvalidType);
  }
  return false;
}

String? _typeAt(CompilationUnit unit, int offset) {
  for (final declaration in unit.declarations) {
    final members = switch (declaration) {
      ClassDeclaration() => declaration.body.members,
      MixinDeclaration() => declaration.body.members,
      ExtensionDeclaration() => declaration.body.members,
      EnumDeclaration() => declaration.body.members,
      _ => const <ClassMember>[],
    };
    for (final member in members) {
      if (member is ConstructorDeclaration) {
        for (final parameter in member.parameters.parameters) {
          if (parameter.name?.offset == offset)
            return parameter.type?.toSource();
        }
      } else if (member is FieldDeclaration) {
        if (member.fields.variables.any(
          (variable) => variable.name.offset == offset,
        )) {
          return member.fields.type?.toSource();
        }
      } else if (member is GetterDeclaration) {
        final getter = member as GetterDeclaration;
        if (getter.name.offset == offset) return getter.returnType?.toSource();
      }
    }
  }
  return null;
}
