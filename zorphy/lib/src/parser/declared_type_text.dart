// ignore_for_file: experimental_member_use

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

String declaredTypeText(DartType type, Fragment fragment) {
  if (type is! InvalidType) return type.getDisplayString();
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

String? _typeAt(CompilationUnit unit, int offset) {
  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    for (final member in declaration.body.members) {
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
