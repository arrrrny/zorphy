import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

abstract class GeneratorForAnnotationX<T> extends Generator {
  const GeneratorForAnnotationX();

  TypeChecker get typeChecker;

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = Set<String>();

    var classElements = library.allElements.whereType<ClassElement>().toList();
    var annotatedElements = library.annotatedWith(typeChecker).toList();

    for (var annotatedElement in annotatedElements) {
      final generatedValue = generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
        classElements,
      );
      values.add(generatedValue.toString());
    }

    return values.join('\n\n');
  }

  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
    List<ClassElement> allClassElements,
  );
}
