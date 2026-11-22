// Release gate for the v3 zero-toggle contract (ISSUE-001).
//
// The runtime tests in `archetypes_test.dart` prove the archetype SURFACE. They
// cannot prove the absence of a `generate*` toggle, nor that `replaySafe` has no
// default: a hand-written test that says `expect(true, isTrue)` passes either
// way, and a future `this.replaySafe = false` default would slip through every
// assertion in that file.
//
// This gate reads the archetype SOURCE through the analyzer's element model —
// the same view the generator sees — and pins both invariants on the real
// constructor parameters, so adding `generateJson` or a `replaySafe` default
// fails here rather than shipping.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';

/// The five archetypes that must stay zero-toggle.
const _archetypes = <String>[
  'ZorphyEntity',
  'ZorphyState',
  'ZorphyUnion',
  'ZorphyIntent',
  'ZorphyValue',
];

/// Resolves `package:zorphy_annotation/zorphy_annotation.dart` through the
/// consumer's own package config, so the gate reads the archetype source this
/// checkout actually ships — no `.dart_tool` state of the annotation package,
/// no pub cache, no path guesswork.
Future<(AnalysisContextCollection, ResolvedLibraryResult)> _resolveArchetypes(
  Directory workspace,
) async {
  final path = '${workspace.path}/archetypes_probe.dart';
  File(path).writeAsStringSync('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
''');
  final collection = AnalysisContextCollection(includedPaths: [workspace.path]);
  final result =
      await collection.contextFor(path).currentSession.getResolvedLibrary(path)
          as ResolvedLibraryResult;
  return (collection, result);
}

/// The imported `zorphy_annotation` library element, found through the
/// probe's own import so nothing depends on where the package lives on disk.
LibraryElement _annotationLibrary(ResolvedLibraryResult probe) {
  for (final import in probe.element.firstFragment.libraryImports) {
    final imported = import.importedLibrary;
    if (imported != null && imported.identifier.contains('zorphy_annotation')) {
      return imported;
    }
  }
  fail('probe did not import package:zorphy_annotation/zorphy_annotation.dart');
}

ClassElement _classNamed(LibraryElement library, String name) {
  final element = library.exportNamespace.definedNames2[name];
  if (element is! ClassElement) {
    fail(
      '$name is not a class reachable from '
      'package:zorphy_annotation/zorphy_annotation.dart',
    );
  }
  return element;
}

List<FormalParameterElement> _defaultConstructorParameters(
  ClassElement element,
) {
  final constructor = element.unnamedConstructor;
  if (constructor == null) {
    fail('${element.name} has no unnamed constructor');
  }
  return constructor.formalParameters;
}

void main() {
  late Directory workspace;
  late LibraryElement annotation;

  setUpAll(() async {
    final root = Directory('test/.archetype_gate_tmp').absolute
      ..createSync(recursive: true);
    workspace = root.createTempSync('probe_');
    final (collection, probe) = await _resolveArchetypes(workspace);
    try {
      annotation = _annotationLibrary(probe);
    } finally {
      await collection.dispose();
    }
  });

  tearDownAll(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  group('zero-toggle guarantee', () {
    for (final name in _archetypes) {
      test('$name exposes no generate* constructor parameter', () {
        final parameters = _defaultConstructorParameters(
          _classNamed(annotation, name),
        );
        final toggles = parameters
            .where((p) => p.name?.startsWith('generate') ?? false)
            .map((p) => p.name)
            .toList();
        expect(
          toggles,
          isEmpty,
          reason:
              'v3 dropped every generate* toggle (ISSUE-001); '
              '$name gained ${toggles.join(', ')}',
        );
      });

      test('$name takes no optional Boolean constructor parameter', () {
        // A toggle is an OPTIONAL Boolean knob — one the caller can leave at a
        // default and flip later. A toggle renamed from `generateX` to
        // `xEnabled` is still a toggle, so the prefix check above is not
        // enough on its own. `ZorphyIntent.replaySafe` is the one legitimate
        // Boolean and it is REQUIRED (pinned separately below), so it cannot
        // be flipped by omission.
        final toggles =
            _defaultConstructorParameters(_classNamed(annotation, name)).where(
              (p) =>
                  p.type is InterfaceType &&
                  (p.type as InterfaceType).element.name == 'bool' &&
                  !p.isRequired,
            );
        expect(
          toggles.map((p) => p.name),
          isEmpty,
          reason: 'v3 archetypes are zero-toggle: no optional Boolean options',
        );
      });
    }
  });

  group('replaySafe has no default', () {
    test('ZorphyIntent.replaySafe is a required named parameter', () {
      final parameters = _defaultConstructorParameters(
        _classNamed(annotation, 'ZorphyIntent'),
      );
      final replaySafe = parameters.where((p) => p.name == 'replaySafe');
      expect(
        replaySafe,
        hasLength(1),
        reason: 'ZorphyIntent must expose a replaySafe parameter',
      );
      final parameter = replaySafe.single;
      expect(
        parameter.isNamed,
        isTrue,
        reason: 'replaySafe is a named parameter',
      );
      expect(
        parameter.isRequiredNamed,
        isTrue,
        reason:
            'replaySafe must stay REQUIRED: a default would silently choose '
            'replay-safety for every intent',
      );
      expect(
        parameter.hasDefaultValue,
        isFalse,
        reason: 'a default value is exactly the regression this gate catches',
      );
      expect(
        parameter.defaultValueCode,
        isNull,
        reason: 'there is no default to fall back on',
      );
    });
  });
}
