import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/analysis/analysis.dart';
import 'package:zorphy/src/models/models.dart';
import 'package:zorphy/src/orchestrator.dart';

/// Unified single-pass generator for `@Zorphy` and `@Zorphy2` classes.
///
/// Since zorphy 2.0 this is the ONLY generator: it handles both
/// annotations, resolves polymorphic ordering internally (topological
/// order over the `implements $$Base` graph, computed per library), and
/// keeps NO process-global mutable state — the annotated-class graph is
/// rebuilt from the library's class list on every pass.
class ZorphyGenerator extends Generator {
  /// Creates the unified generator.
  const ZorphyGenerator();

  static const _zorphyChecker = TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy',
  );
  static const _zorphy2Checker = TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy2',
  );

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    final allClasses = library.allElements.whereType<ClassElement>().toList();
    final graph = ClassGraph.fromLibraryClasses(
      allClasses,
      library: library.element,
    );

    // Collect annotated elements from BOTH annotation types.
    final annotated = <_AnnotatedClass>[];
    for (final cls in allClasses) {
      final isZorphy2 = _zorphy2Checker.hasAnnotationOf(cls);
      final isZorphy = _zorphyChecker.hasAnnotationOf(cls);
      if (!isZorphy && !isZorphy2) continue;
      final annotation = isZorphy
          ? _zorphyChecker.firstAnnotationOf(cls)!
          : _zorphy2Checker.firstAnnotationOf(cls)!;
      annotated.add(
        _AnnotatedClass(
          cls,
          ConstantReader(annotation),
          isZorphy2: isZorphy2 && !isZorphy,
        ),
      );
    }

    // Topological order: base interfaces ($$Base) before implementors.
    final ordered = graph.topological(annotated.map((a) => a.element));
    final byElement = {for (final a in annotated) a.element: a};

    final values = <String>[];
    for (final cls in ordered) {
      final entry = byElement[cls]!;
      final generated = _generateForClass(
        entry.element,
        entry.annotation,
        graph,
        outputExtension: entry.isZorphy2 ? '.zorphy2.dart' : '.zorphy.dart',
      );
      if (generated.isNotEmpty) values.add(generated);
    }

    return values.join('\n\n');
  }

  String _generateForClass(
    ClassElement classElement,
    ConstantReader annotation,
    ClassGraph graph, {
    required String outputExtension,
  }) {
    if (classElement.supertype?.element.name != "Object") {
      throw Exception("you must use implements, not extends");
    }

    // Collect factory methods using the unified analyzer
    final metadata = ClassAnalyzer.analyze(
      classElement,
      annotation,
      graph.annotated,
      graph.classesInExplicitSubtypes,
    );
    final factoryMethods = metadata.factoryMethods;

    // Get own fields (defined directly on this class, not inherited)
    final ownFields = classElement.children
        .whereType<FieldElement>()
        .where((f) => f.name != "hashCode" && f.name != "runtimeType")
        .map((f) => f.name ?? "")
        .toSet();

    // Resolve ALL flags through the single resolution point.
    final options = AnnotationParser.parse(annotation);
    final config = GenerationConfig.fromAnnotationOptions(
      options,
      outputExtension: outputExtension,
      factoryMethods: factoryMethods,
      ownFields: ownFields,
    );

    // Use the orchestrator pipeline
    return Orchestrator.generate(
      classElement,
      annotation,
      graph.annotated,
      config,
      graph.classesInExplicitSubtypes,
    );
  }
}

class _AnnotatedClass {
  final ClassElement element;
  final ConstantReader annotation;
  final bool isZorphy2;

  _AnnotatedClass(this.element, this.annotation, {required this.isZorphy2});
}
