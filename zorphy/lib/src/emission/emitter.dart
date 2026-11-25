import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

/// Emits formatted Dart source from a [Library] spec.
///
/// This is the code_builder emission pipeline entry point.
/// Generators produce [Spec] objects; this class turns them into a
/// single formatted Dart library string.
class ZorphyEmitter {
  /// The language version the emitted source is formatted under.
  ///
  /// The emitted file is later re-formatted by `dart format`, which applies
  /// the CONSUMING package's language version — for this package's own
  /// fixtures that is the pubspec's min SDK (3.11), not the formatter's
  /// newest style. The newest style keeps an over-wide single-string
  /// argument on one line where earlier versions wrap it, so an emission
  /// formatted at `latestLanguageVersion` can be byte-identical to a
  /// fixture OR the fixture can be format-clean, never both (#226). Pin the
  /// emitter to that same floor and bump the two together.
  static final Version formatterLanguageVersion = Version(3, 11, 0);

  /// Default page width used by [DartFormatter].
  ///
  /// 80 follows the Dart style guide convention.
  /// Use [ZorphyEmitter.withPageWidth] to override.
  static const int defaultPageWidth = 80;

  /// Page width configured for this emitter instance.
  final int pageWidth;

  /// The underlying formatter instance (created once, reused).
  final DartFormatter _formatter;

  /// Creates a new emitter with the default page width (80).
  ZorphyEmitter()
    : pageWidth = defaultPageWidth,
      _formatter = DartFormatter(
        languageVersion: formatterLanguageVersion,
        pageWidth: defaultPageWidth,
      );

  /// Creates a new emitter with a custom page width.
  ZorphyEmitter.withPageWidth(int width)
    : pageWidth = width,
      _formatter = DartFormatter(
        languageVersion: formatterLanguageVersion,
        pageWidth: width,
      );

  /// Emits the given [library] spec to a formatted Dart source string.
  ///
  /// When [strict] is `true` (used during validation), a
  /// [FormatterException] is propagated instead of falling back
  /// to raw output. This ensures that the spec pipeline's output
  /// can be compared byte-for-byte against the string pipeline.
  String emit(Library library, {bool strict = false}) {
    final raw = library.accept(DartEmitter()).toString();
    try {
      return _formatter.format(raw);
    } on FormatterException {
      if (strict) rethrow;
      // If formatting fails (e.g. the spec is a partial fragment),
      // return the raw output so the pipeline doesn't crash.
      return raw;
    }
  }

  /// Emits the given [library] spec with strict formatting.
  ///
  /// Convenience wrapper for [emit] with [strict] set to `true`.
  /// Used by the validation/comparison path in the orchestrator.
  String emitStrict(Library library) => emit(library, strict: true);

  /// Convenience: emits a list of [Spec] objects as a single library.
  ///
  /// If the list contains a [Library], that library is used directly.
  /// Otherwise, a new [Library] is created with the given specs as body.
  String emitSpecs(List<Spec> specs, {bool strict = false}) {
    if (specs.isEmpty) return '';

    // If there's already a Library spec, use it.
    final existingLib = specs.whereType<Library>().toList();
    if (specs.length == 1 && existingLib.length == 1) {
      return emit(existingLib.first, strict: strict);
    }

    // Otherwise wrap in a new Library.
    final library = Library((b) {
      for (final spec in specs) {
        if (spec is Library) {
          // Merge its directives and body.
          for (final d in spec.directives) {
            b.directives.add(d);
          }
          for (final body in spec.body) {
            b.body.add(body);
          }
        } else {
          b.body.add(spec);
        }
      }
    });

    return emit(library, strict: strict);
  }
}
