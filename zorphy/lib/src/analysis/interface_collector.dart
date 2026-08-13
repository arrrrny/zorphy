import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../common/NameType.dart';
import '../common/helpers.dart' as helpers;
import '../models/interface_metadata.dart';

/// Collects and analyzes interface hierarchy for a class
/// Handles inheritance, generics, and sealed class detection
class InterfaceCollector {
  /// Collect all interfaces that a class implements
  /// Returns InterfaceWithComment objects with full metadata
  static List<InterfaceMetadata> collect(
    ClassElement classElement,
    Map<String, ClassElement> allAnnotatedClasses,
  ) {
    final allInterfaces = <InterfaceType>[];
    final processedInterfaces = <String>{};
    final className = classElement.name ?? '';

    // Recursively collect interfaces
    void addInterface(InterfaceType interface) {
      var interfaceName = interface.element.name ?? "";
      // Skip Object and other built-in types
      if (interfaceName == "Object" || interfaceName == "Enum") return;
      if (processedInterfaces.contains(interfaceName)) return;
      processedInterfaces.add(interfaceName);
      allInterfaces.add(interface);

      // Recursively add parent interfaces
      for (var supertype in interface.element.allSupertypes) {
        addInterface(supertype);
      }
    }

    // Start collecting from all supertypes
    for (var supertype in classElement.allSupertypes) {
      addInterface(supertype);
    }

    // Convert to InterfaceMetadata with full analysis
    final result = allInterfaces.map((e) {
      var interfaceName = e.element.name ?? "";

      // Check if interface has @Zorphy annotation with nonSealed: true
      var isSealed = interfaceName.startsWith(r'$$');
      if (isSealed && e.element is ClassElement) {
        // Check if the interface has @Zorphy(nonSealed: true)
        var classElement = e.element as ClassElement;
        for (var annotation in classElement.metadata.annotations) {
          var annotationElement = annotation.element;
          if (annotationElement is ConstructorElement) {
            var enclosingElement = annotationElement.enclosingElement;
            if (enclosingElement.name == 'Zorphy') {
              try {
                var constantValue = annotation.computeConstantValue();
                var nonSealedField = constantValue?.getField('nonSealed');
                if (nonSealedField?.toBoolValue() == true) {
                  isSealed = false;
                }
              } catch (_) {}
            }
          }
        }
      }

      return InterfaceMetadata(
        interfaceName, // Don't strip $ prefix - interfaces should keep the $
        e.typeArguments
            .map(
              (t) => helpers.typeToString(
                t,
                currentClassName: className,
                library: classElement.library,
              ),
            )
            .toList(),
        e.element.typeParameters.map((x) => x.name ?? "").toList(),
        e.element.fields
            .map(
              (f) => NameType(
                f.name ?? "",
                helpers.typeToString(
                  f.type,
                  currentClassName: className,
                  library: classElement.library,
                ),
              ),
            )
            .toList(),
        comment: e.element.documentationComment,
        isSealed: isSealed,
        hidePublicConstructor: false,
        element: e.element as ClassElement,
        typeArguments: e.typeArguments,
      );
    }).toList();

    // Issue #304 fix: recover unresolved `implements` clauses from source.
    //
    // When a zorphy source abstract class declares
    //   `implements AuthenticationResult`  (bare name, no `$` prefix)
    // where `AuthenticationResult` is the GENERATED CONCRETE class name
    // (emitted by zorphy into the `.zorphy.dart` file), the analyzer cannot
    // resolve the type at source-analysis time and silently drops it from
    // `classElement.allSupertypes`. This causes the generated concrete
    // class to lose the implements clause, breaking `isA<Base>()` checks
    // and union-type dispatch.
    //
    // We read the source text directly, parse the `implements` clause of
    // the class declaration, and resolve each name against
    // `allAnnotatedClasses` (which holds all zorphy-annotated source
    // classes by their source name, including the `$` prefix). The
    // recovered interface is added with the SOURCE CLASS NAME (e.g.,
    // `$AuthenticationResult`) so the codegen's `_getExtendedParentName`
    // detects the `$` prefix and routes it to `c.extend` (not
    // `c.implements`). This produces `class Sub extends Parent` on the
    // generated concrete class, which:
    //   1. Makes `isA<Parent>()` hold at runtime (via inheritance).
    //   2. Avoids the `non_abstract_class_inherits_abstract_member` error
    //      that would arise from `implements Parent` (which requires
    //      re-implementing all of Parent's generated methods:
    //      copyWithParent, patchWithParent, ==, hashCode, toString, ...).
    //
    // This recovery handles EXISTING source files generated by the old
    // zfa CLI (which emitted bare names). NEW source files (from the
    // fixed zfa CLI) use `$`-prefixed names directly and are resolved by
    // the analyzer without needing this recovery.
    result.addAll(
      _recoverUnresolvedImplements(
        classElement,
        allAnnotatedClasses,
        processedInterfaces,
      ),
    );

    return result;
  }

  /// Recover unresolved `implements` clauses by parsing the source text of
  /// the class declaration.
  ///
  /// Returns [InterfaceMetadata] entries for each name in the `implements`
  /// clause that:
  ///   1. Is NOT already in [processedInterfaces] (by trimmed name).
  ///   2. Can be resolved against [allAnnotatedClasses] (trying bare name,
  ///      `$Name`, and `$$Name` variants).
  ///
  /// Names that cannot be resolved are silently skipped — they may refer
  /// to non-zorphy types (e.g., dart:core interfaces) that the analyzer
  /// will resolve correctly through the normal supertype chain.
  ///
  /// The returned [InterfaceMetadata.interfaceName] uses the SOURCE CLASS
  /// NAME (e.g., `$AuthenticationResult`) — NOT the bare name as written
  /// in source. This ensures the codegen's `_getExtendedParentName`
  /// detects the `$` prefix and routes the interface to `c.extend`,
  /// producing `class Sub extends Parent` on the concrete class.
  static List<InterfaceMetadata> _recoverUnresolvedImplements(
    ClassElement classElement,
    Map<String, ClassElement> allAnnotatedClasses,
    Set<String> processedInterfaces,
  ) {
    final className = classElement.name ?? '';
    if (className.isEmpty) return const [];

    // Get the source text of the file containing the class.
    //
    // The analyzer API moved the `source` getter around between versions:
    //   - In older versions: `Element.source` was available directly.
    //   - In newer versions (13.x+): `source` is on `Fragment`, accessed
    //     via `Element.firstFragment.source` or `Element.declaration.source`.
    //   - `LibraryElement.source` remains stable across versions.
    //
    // We try multiple paths via dynamic dispatch to be version-agnostic.
    String sourceText;
    try {
      final dynamic dynElem = classElement;
      dynamic sourceObj;
      try {
        sourceObj = dynElem.source;
      } catch (_) {}
      if (sourceObj == null) {
        try {
          // Newer analyzer: access via firstFragment.
          sourceObj = (dynElem.firstFragment as dynamic)?.source;
        } catch (_) {}
      }
      if (sourceObj == null) {
        try {
          // Alternate path: via declaration.
          sourceObj = (dynElem.declaration as dynamic)?.source;
        } catch (_) {}
      }
      if (sourceObj == null) {
        try {
          // Fallback: library-level source (same file for top-level classes).
          sourceObj = (dynElem.library as dynamic)?.source;
        } catch (_) {}
      }
      if (sourceObj == null) {
        return const [];
      }
      sourceText = (sourceObj.contents.data as dynamic).toString();
    } catch (_) {
      return const [];
    }

    // Locate this class's declaration header in the source text.
    //
    // We match the class header (from the `class` keyword up to the body
    // opening `{`) using a regex. This avoids depending on analyzer
    // offset APIs that moved around between analyzer versions.
    //
    // The header pattern handles:
    //   - optional modifiers: `abstract`, `sealed`, `base`, `final`,
    //     `interface`
    //   - the `class` keyword
    //   - the class name (escaped to handle `$`-prefixed names)
    //   - optional generics `<...>`, `extends X`, `with M`, `implements Y`
    //   - up to the body `{`
    //
    // We capture only the segment between `class $Name` and `{`.
    final escapedName = RegExp.escape(className);
    final headerRegex = RegExp(
      // Modifiers (any combination, in any order, separated by whitespace).
      r'(?:[\s]*(?:abstract|sealed|base|final|interface)[\s]+)*' +
      r'class\s+' +
      escapedName +
      r'\b' +
      // Everything up to the body `{`. We match `{` only at depth 0
      // (outside generic `<...>`), but since RegExp has no recursion,
      // we approximate by matching any char that isn't `{`. This works
      // for zorphy source classes (no `{` in type bounds).
      r'([^{]*)\{',
      multiLine: true,
    );
    final headerMatch = headerRegex.firstMatch(sourceText);
    if (headerMatch == null) return const [];
    final headerTail = headerMatch.group(1) ?? '';
    if (headerTail.isEmpty) return const [];

    // Find `implements` keyword in the header tail. Everything after it
    // (until end of header tail) is the comma-separated list of
    // implemented types.
    //
    // We must be careful: `implements` could appear as a substring of a
    // type name (unlikely but possible). Use a word boundary.
    final implMatch = RegExp(
      r'\bimplements\s+(.+)$',
      multiLine: true,
      dotAll: true,
    ).firstMatch(headerTail);
    if (implMatch == null) return const [];

    final implListStr = implMatch.group(1)!.trim();
    if (implListStr.isEmpty) return const [];

    // Split by comma, then strip generic type arguments from each name
    // (e.g., `Foo<Bar>` → `Foo`). We only need the bare name to resolve
    // against `allAnnotatedClasses`.
    final names = <String>[];
    for (final part in implListStr.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final nameMatch = RegExp(r'^[\$?\w]+').firstMatch(trimmed);
      final name = nameMatch?.group(0);
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }

    if (names.isEmpty) return const [];

    final result = <InterfaceMetadata>[];
    for (final name in names) {
      // Skip if already collected (by trimmed name comparison).
      final trimmedName = _trimDollarPrefix(name);
      final alreadyCollected = processedInterfaces.any(
        (p) => _trimDollarPrefix(p) == trimmedName,
      );
      if (alreadyCollected) continue;

      // Look up the ClassElement by trying $ variants. The source class
      // declaration may use the bare name (e.g., `AuthenticationResult`)
      // or a `$`-prefixed name (e.g., `$AuthenticationResult`).
      // `allAnnotatedClasses` keys by the source class name which
      // includes the `$` prefix (e.g., `$AuthenticationResult`).
      final element = allAnnotatedClasses[name] ??
          allAnnotatedClasses['\$$name'] ??
          allAnnotatedClasses['\$\$$name'];
      if (element == null) {
        // Cannot resolve — likely a non-zorphy type (e.g., dart:core).
        // The analyzer will resolve it correctly through the normal
        // supertype chain, so we skip silently.
        continue;
      }

      final sourceName = element.name ?? name;
      final isSealed = sourceName.startsWith(r'$$');

      // Build the InterfaceMetadata using the SOURCE CLASS NAME (with
      // the `$` prefix). This is critical: the codegen's
      // `_getExtendedParentName` only returns interfaces whose names
      // start with `$`, and routes them to `c.extend` (producing
      // `class Sub extends Parent`). If we used the bare name, the
      // codegen would route it to `c.implements` (producing
      // `class Sub implements Parent`), which fails to compile because
      // the parent concrete class has many generated methods that the
      // subclass would need to re-implement.
      result.add(
        InterfaceMetadata(
          sourceName,
          const [], // type args - empty for now (recovery does not resolve generics).
          element.typeParameters.map((x) => x.name ?? '').toList(),
          element.fields
              .where((f) => f.name != 'hashCode' && f.name != 'runtimeType')
              .map(
                (f) => NameType(
                  f.name ?? '',
                  helpers.typeToString(
                    f.type,
                    currentClassName: className,
                    library: classElement.library,
                  ),
                ),
              )
              .toList(),
          comment: element.documentationComment,
          isSealed: isSealed,
          hidePublicConstructor: false,
          element: element,
          typeArguments: const [],
        ),
      );

      // Mark as processed to avoid duplicate recovery.
      processedInterfaces.add(sourceName);
    }

    return result;
  }

  /// Strip leading `$` or `$$` prefix from a class name.
  static String _trimDollarPrefix(String name) {
    if (name.startsWith(r'$$')) return name.substring(2);
    if (name.startsWith(r'$')) return name.substring(1);
    return name;
  }
}
