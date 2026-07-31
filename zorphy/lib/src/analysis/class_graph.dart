import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Per-library graph of zorphy-annotated classes.
///
/// Replaces the process-global static maps that the pre-2.0 double-pass
/// builders used for cross-class resolution. A fresh instance is built
/// from the library's class list on every generation pass, so build_runner
/// caching/invalidation works correctly and no mutable global state
/// exists.
class ClassGraph {
  /// All zorphy/zorphy2-annotated classes in the library, by name.
  /// Includes classes referenced via `explicitSubTypes` even when those
  /// classes live outside the current library's annotated set.
  final Map<String, ClassElement> annotated;

  /// Names of every class referenced by any `explicitSubTypes` list.
  final Set<String> classesInExplicitSubtypes;

  ClassGraph._(this.annotated, this.classesInExplicitSubtypes);

  static const _zorphyChecker = TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy',
  );
  static const _zorphy2Checker = TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy2',
  );

  /// Whether [element] carries a @Zorphy or @Zorphy2 annotation.
  static bool isAnnotated(ClassElement element) =>
      _zorphyChecker.hasAnnotationOf(element) ||
      _zorphy2Checker.hasAnnotationOf(element);

  /// Builds the graph from all classes visible in the current library,
  /// plus zorphy-annotated classes reachable through the library's
  /// imports (cross-library field types like `List<$User>` need the
  /// referenced class present for nested patch/filter generation).
  factory ClassGraph.fromLibraryClasses(
    List<ClassElement> allClasses, {
    LibraryElement? library,
  }) {
    final annotated = <String, ClassElement>{};
    final inExplicitSubtypes = <String>{};

    void register(ClassElement cls) {
      final name = cls.name;
      if (name != null) annotated[name] = cls;

      final annotation =
          _zorphyChecker.firstAnnotationOf(cls) ??
          _zorphy2Checker.firstAnnotationOf(cls);
      final explicitField = annotation?.getField('explicitSubTypes');
      if (explicitField == null || explicitField.isNull) return;
      final subtypes = explicitField.toListValue();
      if (subtypes == null) return;
      for (final subtype in subtypes) {
        final element = subtype.toTypeValue()?.element;
        if (element is ClassElement) {
          final subtypeName = element.name;
          if (subtypeName != null) {
            inExplicitSubtypes.add(subtypeName);
            // Explicit subtypes may be declared in another library and
            // therefore absent from allClasses — register them so field
            // collection can resolve them.
            annotated[subtypeName] = element;
          }
        }
      }
    }

    for (final cls in allClasses) {
      if (isAnnotated(cls)) register(cls);
    }

    // Merge annotated classes from directly imported libraries so
    // cross-library hierarchies and field types resolve without any
    // process-global state.
    if (library != null) {
      for (final imported in library.firstFragment.importedLibraries) {
        for (final cls in imported.classes) {
          if (!annotated.containsKey(cls.name) && isAnnotated(cls)) {
            register(cls);
          }
        }
      }
    }

    return ClassGraph._(annotated, inExplicitSubtypes);
  }

  /// Returns [classes] sorted so base interfaces (`$$Base`) are emitted
  /// before the classes that implement them (topological order over the
  /// `implements` graph). Relative order of independent classes is
  /// preserved (stable sort via Kahn's algorithm with source-order queue).
  List<ClassElement> topological(Iterable<ClassElement> classes) {
    final byName = <String, ClassElement>{};
    for (final cls in classes) {
      final name = cls.name;
      if (name != null) byName[name] = cls;
    }

    final result = <ClassElement>[];
    final emitted = <String>{};
    final remaining = classes.toList();

    // Iterate until stable; guards against cycles by emitting whatever is
    // left in source order after no progress can be made.
    var progress = true;
    while (remaining.isNotEmpty && progress) {
      progress = false;
      for (final cls in remaining.toList()) {
        final deps = cls.allSupertypes
            .map((t) => t.element.name)
            .where(
              (name) =>
                  name != null &&
                  name != 'Object' &&
                  byName.containsKey(name) &&
                  !emitted.contains(name),
            )
            .toList();
        if (deps.isEmpty) {
          result.add(cls);
          emitted.add(cls.name ?? '');
          remaining.remove(cls);
          progress = true;
        }
      }
    }
    // Cyclic or unresolved remnants keep source order.
    result.addAll(remaining);
    return result;
  }
}
