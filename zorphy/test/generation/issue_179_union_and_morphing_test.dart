// Tests for issue #179 (ISSUE-004): sibling `changeTo<Subtype>()` morphing
// methods and `when` / `maybeWhen` union helpers.
//
// §2 asks for a morphing method that carries the shared `$Parent` fields
// across with zero boilerplate:
//
//   extension OrderNotificationMorphing on OrderNotification {
//     PriceDropNotification changeToPriceDropNotification({
//       required String productId,
//       required double oldPrice,
//       required double newPrice,
//       DateTime? createdAt,
//       DateTime? readAt,
//     }) => PriceDropNotification(
//       id: id,
//       createdAt: createdAt ?? this.createdAt,
//       readAt: readAt ?? this.readAt,
//       productId: productId,
//       oldPrice: oldPrice,
//       newPrice: newPrice,
//     );
//   }
//
// and for `when` / `maybeWhen` on a union hierarchy, so matching is
// available at expression level alongside Dart 3 `switch`.
//
// The tests drive the REAL pipeline (resolved ClassElement -> ClassAnalyzer ->
// Orchestrator.generate) and then run the analyzer over the generated sources,
// so a body that does not compile is a failure here rather than a broken part
// file for a consumer. They also prove the emitted morphing extension needs NO
// JSON surface: `generateJson` is off (the default in every preset), so the
// #159/#161 gate that withholds the JSON round-trip `changeTo` must not apply
// to this emitter.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/analysis/annotation_parser.dart';
import 'package:zorphy/src/analysis/class_analyzer.dart';
import 'package:zorphy/src/analysis/class_graph.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy/src/orchestrator.dart';

const _zorphyChecker = TypeChecker.fromUrl(
  'package:zorphy_annotation/src/annotations.dart#Zorphy',
);

/// The shape from §2: two siblings sharing a `$Parent` root with
/// `id`/`createdAt`/`readAt`. `generateJson` is deliberately absent — the
/// sibling morphing method must not depend on a JSON round-trip.
const _notificationSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'notification.zorphy.dart';

@Zorphy(explicitSubTypes: [\$OrderNotification, \$PriceDropNotification])
abstract class \$Notification {
  String get id;

  DateTime get createdAt;

  DateTime? get readAt;
}

@Zorphy()
abstract class \$OrderNotification implements \$Notification {
  String get orderId;
}

@Zorphy()
abstract class \$PriceDropNotification implements \$Notification {
  String get productId;

  double get oldPrice;

  double get newPrice;
}
''';

/// The sealed shape from §5: `$$Notification` is a closed hierarchy whose
/// root may be emitted `sealed`, which is what makes `when`'s `switch`
/// exhaustive. A single-`$` base is a concrete class and hosts no matcher.
const _sealedNotificationSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'notification.zorphy.dart';

@Zorphy(explicitSubTypes: [\$OrderNotification, \$PriceDropNotification])
abstract class \$\$Notification {
  String get id;

  DateTime get createdAt;

  DateTime? get readAt;
}

@Zorphy()
abstract class \$OrderNotification implements \$\$Notification {
  String get orderId;
}

@Zorphy()
abstract class \$PriceDropNotification implements \$\$Notification {
  String get productId;

  double get oldPrice;

  double get newPrice;
}
''';

/// The generic shape from §5: a `@ZorphyUnion`-style hierarchy over a type
/// parameter, whose emitted `switch` must be exhaustive for every `T`. This is
/// the `AsyncSlice<T>` acceptance criterion — a generic hierarchy must not
/// degrade into a non-exhaustive matcher just because `T` is open.
const _genericSliceSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'slice.zorphy.dart';

@Zorphy(explicitSubTypes: [\$SliceData, \$SliceLoading])
abstract class \$\$AsyncSlice<T> {
  String get source;
}

@Zorphy()
abstract class \$SliceData<T> implements \$\$AsyncSlice<T> {
  T get value;
}

@Zorphy()
abstract class \$SliceLoading<T> implements \$\$AsyncSlice<T> {}
''';

/// Resolves every `@Zorphy` class in [libraryPath] and returns the generated
/// part bodies keyed by class name.
Future<Map<String, String>> _generateLibrary(String libraryPath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [Directory(libraryPath).parent.path],
  );
  final outputs = <String, String>{};
  try {
    final result =
        await collection
                .contextFor(libraryPath)
                .currentSession
                .getResolvedUnit(libraryPath)
            as ResolvedUnitResult;
    final graph = ClassGraph.fromLibraryClasses(
      result.libraryElement.classes.toList(),
      library: result.libraryElement,
    );
    for (final element in result.libraryElement.classes) {
      final annotation = _zorphyChecker.firstAnnotationOf(element);
      if (annotation == null) continue;
      final annotationReader = ConstantReader(annotation);

      final metadata = ClassAnalyzer.analyze(
        element,
        annotationReader,
        graph.annotated,
        graph.classesInExplicitSubtypes,
      );

      final ownFields = element.children
          .whereType<FieldElement>()
          .where((f) => f.name != 'hashCode' && f.name != 'runtimeType')
          .map((f) => f.name ?? '')
          .toSet();
      final options = AnnotationParser.parse(annotationReader);
      final config = GenerationConfig.fromAnnotationOptions(
        options,
        outputExtension: '.zorphy.dart',
        factoryMethods: metadata.factoryMethods,
        ownFields: ownFields,
      );

      outputs[element.displayName] = Orchestrator.generate(
        element,
        annotationReader,
        graph.annotated,
        config,
        graph.classesInExplicitSubtypes,
      );
    }
    return outputs;
  } finally {
    await collection.dispose();
  }
}

/// Writes [generated] next to the library as its generated part file.
void _writePart(
  Directory fixtureDir,
  String libraryName,
  String partName,
  String generated,
) {
  File(
    '${fixtureDir.path}/$partName',
  ).writeAsStringSync("part of '$libraryName';\n\n$generated");
}

/// Every diagnostic the analyzer reports for the library at [libraryPath]
/// (including its generated part file), formatted as
/// `<file>:<offset>: <code> — <message>`.
Future<List<String>> _diagnostics(
  Directory fixtureDir,
  String libraryPath,
) async {
  final collection = AnalysisContextCollection(
    includedPaths: [fixtureDir.path],
  );
  final diagnostics = <String>[];
  try {
    final library =
        await collection
                .contextFor(libraryPath)
                .currentSession
                .getResolvedLibrary(libraryPath)
            as ResolvedLibraryResult;
    for (final unit in library.units) {
      for (final diagnostic in unit.diagnostics) {
        diagnostics.add(
          '${unit.path.split('/').last}:'
          '${diagnostic.problemMessage.offset}: '
          '${diagnostic.diagnosticCode.lowerCaseName} — '
          '${diagnostic.problemMessage.messageText(includeUrl: false)}',
        );
      }
    }
    return diagnostics;
  } finally {
    await collection.dispose();
  }
}

/// Diagnostics that mean the generated part references a member that does not
/// exist — the failure class a broken morphing body produces.
bool _isMissingMember(String diagnostic) =>
    diagnostic.contains('undefined_instance_member_read') ||
    diagnostic.contains('undefined_static_member_read') ||
    diagnostic.contains('undefined_identifier') ||
    diagnostic.contains('undefined_getter') ||
    diagnostic.contains('undefined_method') ||
    diagnostic.contains('not_a_type') ||
    diagnostic.contains('invalid_assignment') ||
    diagnostic.contains('argument_type_not_assignable') ||
    diagnostic.contains('missing_required_argument') ||
    diagnostic.contains('extra_positional_arguments');

void main() {
  group('issue #179 — sibling morphing (changeTo*)', () {
    late Directory fixtureDir;
    late String libraryPath;
    late Map<String, String> outputs;
    late List<String> diagnostics;
    late String order;

    setUpAll(() async {
      final root = Directory('test/.issue_179_morphing_tmp').absolute.path;
      fixtureDir = Directory(root)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      libraryPath = '${fixtureDir.path}/notification.dart';
      File(libraryPath).writeAsStringSync(_notificationSource);

      outputs = await _generateLibrary(libraryPath);
      _writePart(
        fixtureDir,
        'notification.dart',
        'notification.zorphy.dart',
        outputs.values.join('\n\n'),
      );

      diagnostics = await _diagnostics(fixtureDir, libraryPath);
      order = outputs.entries
          .firstWhere((e) => e.key.contains('OrderNotification'))
          .value;
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_179_morphing_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    test('emits changeTo<Sibling> on the sibling-sharing subtype', () {
      expect(
        order,
        contains('changeToPriceDropNotification'),
        reason:
            'a subtype must expose a morphing method for each sibling that '
            r'shares its \$Parent',
      );
    });

    test('the morphing method takes the target-only fields', () {
      // §2: the target's own fields are required; the shared ones are
      // optional so a caller can override them without restating them.
      expect(order, contains('required String productId'));
      expect(order, contains('required double oldPrice'));
      expect(order, contains('required double newPrice'));
      expect(order, contains('DateTime? createdAt'));
      expect(order, contains('DateTime? readAt'));
    });

    test(r'shared $Parent fields are copied automatically', () {
      // The whole point: `id` is carried across with zero boilerplate, and
      // the optional shared fields default to the receiver's values.
      expect(
        order,
        contains('id: id'),
        reason: 'the shared principal field must flow through untouched',
      );
      expect(
        order,
        contains('createdAt: createdAt ?? this.createdAt'),
        reason: 'an unset shared field keeps the receiver value',
      );
      expect(
        order,
        contains('readAt: readAt ?? this.readAt'),
        reason: 'an unset shared field keeps the receiver value',
      );
    });

    test('morphing needs no JSON surface', () {
      // `generateJson` is off here; the JSON round-trip changeTo of #159 is
      // correctly withheld, but sibling morphing must still be emitted.
      final all = outputs.values.join('\n');
      expect(
        all,
        contains('changeToPriceDropNotification'),
        reason: 'sibling morphing must not be gated on generateJson',
      );
    });

    test('no sibling morphing method targets the receiver itself', () {
      expect(
        order,
        isNot(contains('changeToOrderNotification')),
        reason: 'morphing to your own type is copyWith, not a morph',
      );
    });

    test('generated library analyzes with no missing-member diagnostics', () {
      expect(
        diagnostics.where(_isMissingMember),
        isEmpty,
        reason:
            'the morphing body must compile. diagnostics:\n'
            '${diagnostics.join('\n')}',
      );
    });
  });

  group('issue #179 — when / maybeWhen on a union hierarchy', () {
    late Directory fixtureDir;
    late String libraryPath;
    late Map<String, String> outputs;
    late List<String> diagnostics;
    late String base;

    setUpAll(() async {
      final root = Directory('test/.issue_179_union_tmp').absolute.path;
      fixtureDir = Directory(root)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      libraryPath = '${fixtureDir.path}/notification.dart';
      File(libraryPath).writeAsStringSync(_sealedNotificationSource);

      outputs = await _generateLibrary(libraryPath);
      _writePart(
        fixtureDir,
        'notification.dart',
        'notification.zorphy.dart',
        outputs.values.join('\n\n'),
      );

      diagnostics = await _diagnostics(fixtureDir, libraryPath);
      base = outputs.entries
          .firstWhere((e) => e.key == r'$$Notification')
          .value;
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_179_union_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    test('emits when with one callback per declared subtype', () {
      expect(base, contains('when<T>('));
      expect(base, contains('required T Function(OrderNotification)'));
      expect(base, contains('required T Function(PriceDropNotification)'));
    });

    test('emits maybeWhen with an orElse fallback', () {
      expect(base, contains('maybeWhen<T>('));
      expect(base, contains('required T Function() orElse'));
    });

    test('when dispatches with a Dart 3 switch over the runtime type', () {
      expect(base, contains('switch (this)'));
    });

    test('when bodies compile', () {
      expect(
        diagnostics.where(_isMissingMember),
        isEmpty,
        reason:
            'the when/maybeWhen helpers must compile. diagnostics:\n'
            '${diagnostics.join('\n')}',
      );
    });
  });

  group('issue #179 — generic hierarchy carries its type parameters', () {
    late Directory fixtureDir;
    late String libraryPath;
    late Map<String, String> outputs;
    late String root;
    late String loading;

    setUpAll(() async {
      final rootDir = Directory('test/.issue_179_generic_tmp').absolute.path;
      fixtureDir = Directory(rootDir)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      libraryPath = '${fixtureDir.path}/slice.dart';
      File(libraryPath).writeAsStringSync(_genericSliceSource);

      outputs = await _generateLibrary(libraryPath);
      root = outputs.entries.firstWhere((e) => e.key == r'$$AsyncSlice').value;
      loading = outputs.entries
          .firstWhere((e) => e.key == r'$SliceLoading')
          .value;
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_179_generic_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    // The emitter's own contract on a generic hierarchy. Whether the emitted
    // subclass declarations make the ROOT's switch exhaustive is a separate,
    // pre-existing defect: `ClassDeclarationGenerator` drops the type
    // arguments on `implements` (`class SliceData<T> implements AsyncSlice`),
    // so a generic subtype implements `AsyncSlice<dynamic>` and no matcher
    // over `AsyncSlice<T>` can be exhaustive. Reported on the PR, not fixed
    // here — the issue's literal ask is the non-generic §2 shape.
    test('the matcher does not shadow the class type parameter', () {
      // `when<T>` inside `on AsyncSlice<T>` would rebind every `T` in the
      // extension and break the arms; the return type parameter must differ.
      expect(root, contains('when<TResult>('));
      expect(root, contains('maybeWhen<TResult>('));
      expect(root, isNot(contains('when<T>(')));
    });

    test('the extension and every arm keep the class type arguments', () {
      expect(root, contains('on AsyncSlice<T>'));
      expect(root, contains('required TResult Function(SliceData<T>)'));
      expect(root, contains('SliceLoading<T> value =>'));
    });

    test('morphing on a generic sibling is generic too', () {
      expect(loading, contains('extension SliceLoadingMorphing<T>'));
      expect(loading, contains('on SliceLoading<T>'));
      expect(loading, contains('SliceData<T> changeToSliceData('));
      expect(loading, contains('SliceData<T>('));
    });
  });

  group('issue #179 — behavior: morphing preserves shared fields', () {
    // Runtime proof, executed in the example package context (the zorphy test
    // package cannot import the example package's generated code). The
    // fixture is `example/lib/various/issue_179_union_morphing.dart`; CI
    // regenerates it before tests run.
    test('behavior check runner exits 0 and reports no failures', () {
      final result = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'tool/issue_179_behavior_check.dart',
      ], workingDirectory: 'example');

      final combined = '${result.stdout}\n${result.stderr}';
      expect(
        result.exitCode,
        0,
        reason: 'issue #179 behavior checks failed. output:\n$combined',
      );
      expect(combined, contains('ALL CHECKS PASSED'));
      expect(combined, isNot(contains('FAIL:')));
    });
  });
}
