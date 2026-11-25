/// Strips a v2 file's stale part directives for the v3 shared-part layout
/// (#249).
///
/// v3 attaches its generated code itself (`adds_to_library: true` in
/// `zorphy/build.yaml`): build_runner writes the `part` directive into the
/// library, so a migrated file keeps no hand-written parts. The 2.x
/// `part '<name>.zorphy.dart';` directive is dead in every file, and the v2
/// json_serializable `part '<name>.g.dart';` belongs only to files that
/// declare their own `@JsonSerializable` classes.
///
/// [PartDirectiveCleaner.clean] removes every `.zorphy.dart` directive
/// (always) and — when [PartDirectiveCleanArg.stripJsonParts] is set — every
/// `.g.dart` directive, re-inserting exactly one clean
/// `part '<name>.g.dart';` when the library declares `@JsonSerializable`
/// classes. The removed `.zorphy.dart` URIs are reported so the CLI can
/// delete the stale files under `--apply`. Unparseable source is returned
/// unchanged — never edit blind.
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// One source-span removal (`[start, end)` deleted from the source).
class _Removal {
  final int start;
  final int end;

  const _Removal(this.start, this.end);
}

/// The outcome of cleaning one source file.
class PartDirectiveCleanResult {
  /// The source with the stale directives removed (and the clean json part
  /// re-inserted, when applicable).
  final String source;

  /// URIs of the removed `part '*.zorphy.dart';` directives — the stale 2.x
  /// files the CLI deletes under `--apply`.
  final List<String> removedZorphyParts;

  /// URIs of the removed `part '*.g.dart';` directives.
  final List<String> removedJsonParts;

  /// The clean `part '<name>.g.dart';` re-inserted for a file that declares
  /// its own `@JsonSerializable` classes; null when nothing was restored.
  final String? restoredJsonPart;

  const PartDirectiveCleanResult(
    this.source,
    this.removedZorphyParts,
    this.removedJsonParts,
    this.restoredJsonPart,
  );

  /// A result that leaves [source] byte-for-byte unchanged.
  const PartDirectiveCleanResult.unchanged(String source)
    : this(source, const <String>[], const <String>[], null);

  /// Whether the cleaning touched the source at all.
  bool get changed =>
      removedZorphyParts.isNotEmpty ||
      removedJsonParts.isNotEmpty ||
      restoredJsonPart != null;
}

/// The arguments of [PartDirectiveCleaner.clean].
class PartDirectiveCleanArg {
  /// The source of the library file being cleaned.
  final String source;

  /// The library file's own name (`user.dart`), used to name the clean
  /// `part '<name>.g.dart';` when one must be restored. Without it the first
  /// removed `.g.dart` URI is reused.
  final String? libraryFileName;

  /// Whether the `.g.dart` directives may be stripped. The caller sets this
  /// only for files the codemod actually migrates (a v2 construct is
  /// present), so an unrelated json_serializable file passes through
  /// untouched.
  final bool stripJsonParts;

  const PartDirectiveCleanArg({
    required this.source,
    this.libraryFileName,
    this.stripJsonParts = false,
  });
}

/// The v2 part-directive cleaner (#249).
class PartDirectiveCleaner {
  const PartDirectiveCleaner._();

  /// Returns [source] with the stale part directives removed.
  ///
  /// `part '*.zorphy.dart';` directives are removed unconditionally — no v3
  /// library keeps a hand-written zorphy part. `part '*.g.dart';`
  /// directives are removed only when [arg.stripJsonParts] is set; a file
  /// that declares its own `@JsonSerializable` classes then gets exactly one
  /// clean `part '<name>.g.dart';` back (named from [arg.libraryFileName]).
  /// An unparseable file is returned unchanged.
  static PartDirectiveCleanResult clean(PartDirectiveCleanArg arg) {
    final source = arg.source;
    CompilationUnit unit;
    try {
      unit = parseString(content: source).unit;
    } on ArgumentError {
      return PartDirectiveCleanResult.unchanged(source);
    }

    final removals = <_Removal>[];
    final zorphyParts = <String>[];
    final jsonParts = <String>[];
    for (final directive in unit.directives) {
      if (directive is! PartDirective) continue;
      final uri = directive.uri.stringValue;
      if (uri == null) continue;
      if (uri.endsWith('.zorphy.dart')) {
        removals.add(_Removal(directive.offset, directive.end));
        zorphyParts.add(uri);
      } else if (arg.stripJsonParts && uri.endsWith('.g.dart')) {
        removals.add(_Removal(directive.offset, directive.end));
        jsonParts.add(uri);
      }
    }
    if (removals.isEmpty) return PartDirectiveCleanResult.unchanged(source);

    String? restored;
    if (arg.stripJsonParts &&
        jsonParts.isNotEmpty &&
        _declaresJsonSerializable(unit)) {
      restored = _cleanJsonUri(arg.libraryFileName, jsonParts);
    }

    var result = source;
    final sorted = [...removals]..sort((a, b) => b.start.compareTo(a.start));
    for (final removal in sorted) {
      result = result.replaceRange(removal.start, removal.end, '');
    }
    if (restored != null) {
      final at = _insertionOffset(unit, removals);
      result = result.replaceRange(at, at, "\npart '$restored';");
    }
    return PartDirectiveCleanResult(result, zorphyParts, jsonParts, restored);
  }

  /// Whether any class in [unit] carries `@JsonSerializable` — such a file
  /// keeps a (clean) `.g.dart` part for its own DTOs.
  static bool _declaresJsonSerializable(CompilationUnit unit) {
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      for (final meta in declaration.metadata) {
        if (meta.name.name == 'JsonSerializable') return true;
      }
    }
    return false;
  }

  /// The URI of the restored json part: named after the library file when
  /// known, else the first URI that was removed (dedupe with an unknown
  /// library name).
  static String? _cleanJsonUri(
    String? libraryFileName,
    List<String> removedJsonParts,
  ) {
    final name = libraryFileName;
    if (name != null && name.endsWith('.dart')) {
      return '${name.substring(0, name.length - '.dart'.length)}.g.dart';
    }
    return removedJsonParts.isEmpty ? null : removedJsonParts.first;
  }

  /// The offset (in the ALREADY-REMOVED result) where the restored directive
  /// belongs: right after the last directive that survived the cleaning, so
  /// it stays inside the directive region.
  static int _insertionOffset(CompilationUnit unit, List<_Removal> removals) {
    Directive? lastKept;
    for (final directive in unit.directives) {
      final removed = removals.any(
        (removal) => removal.start == directive.offset,
      );
      if (!removed) lastKept = directive;
    }
    int shiftBefore(int offset) {
      var shift = 0;
      for (final removal in removals) {
        if (removal.start < offset) shift += removal.end - removal.start;
      }
      return offset - shift;
    }

    if (lastKept != null) return shiftBefore(lastKept.end);
    // Every directive was removed: restore where the first one started.
    final first = removals.reduce((a, b) => a.start < b.start ? a : b);
    return shiftBefore(first.start);
  }
}
