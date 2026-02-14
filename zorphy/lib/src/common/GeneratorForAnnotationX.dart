import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Base generator that processes elements annotated with [T].
abstract class GeneratorForAnnotationX<T> extends Generator {
  /// Creates a generator for a specific annotation type.
  const GeneratorForAnnotationX();

  /// Returns the type checker for the annotation.
  TypeChecker get typeChecker;

  @override
  /// Generates code for all annotated elements in a library.
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

  /// Generates code for a single annotated element.
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
    List<ClassElement> allClassElements,
  );
}
