import 'merge_types.dart';

/// AST-based diff between an existing file and newly generated content.
///
/// Uses lightweight pattern matching to extract top-level declarations
/// from both files and compare them. Forzorphy's generated files,
/// the structure is predictable (single generated class + extensions),
/// so a full analyzer parse is unnecessary for diff purposes.
class AstDiff {
  /// Compare [existingSource] with [generatedSource] and return a list
  /// of [DiffEntry] items describing the differences.
  static List<DiffEntry> diff({
    required String existingSource,
    required String generatedSource,
    String? filePath,
  }) {
    final existingLines = existingSource.split('\n');
    final generatedLines = generatedSource.split('\n');

    // Quick path: identical content.
    if (existingSource == generatedSource) return [];

    final entries = <DiffEntry>[];

    final existingDecls = _extractDeclarations(existingLines);
    final generatedDecls = _extractDeclarations(generatedLines);

    final existingByName = {for (final d in existingDecls) d.name: d};
    final generatedByName = {for (final d in generatedDecls) d.name: d};

    // Find modifications and removals.
    for (final existing in existingDecls) {
      final generated = generatedByName[existing.name];
      if (generated == null) {
        entries.add(DiffEntry(
          description: 'Removed: ${existing.kind} ${existing.name}',
          type: DiffType.removed,
          oldLine: existing.startLine,
          newLine: -1,
        ));
      } else {
        final oldContent = existingLines
            .sublist(existing.startLine, existing.endLine)
            .join('\n');
        final newContent = generatedLines
            .sublist(generated.startLine, generated.endLine)
            .join('\n');
        if (oldContent != newContent) {
          entries.add(DiffEntry(
            description: 'Modified: ${existing.kind} ${existing.name}',
            type: DiffType.modified,
            oldLine: existing.startLine,
            newLine: generated.startLine,
          ));
        }
      }
    }

    // Find additions.
    for (final generated in generatedDecls) {
      if (!existingByName.containsKey(generated.name)) {
        entries.add(DiffEntry(
          description: 'Added: ${generated.kind} ${generated.name}',
          type: DiffType.added,
          oldLine: -1,
          newLine: generated.startLine,
        ));
      }
    }

    // Check for header changes.
    final existingHeaderEnd =
        existingDecls.isEmpty ? existingLines.length : existingDecls.first.startLine;
    final generatedHeaderEnd =
        generatedDecls.isEmpty ? generatedLines.length : generatedDecls.first.startLine;

    if (existingLines.sublist(0, existingHeaderEnd).join('\n') !=
        generatedLines.sublist(0, generatedHeaderEnd).join('\n')) {
      entries.add(DiffEntry(
        description: 'Modified: file header (imports/comments)',
        type: DiffType.modified,
        oldLine: 0,
        newLine: 0,
      ));
    }

    return entries;
  }

  /// Build a human-readable diff summary.
  static String buildSummary(List<DiffEntry> entries) {
    if (entries.isEmpty) return '';
    return entries.map((e) => e.toString()).join('\n');
  }

  static List<_Decl> _extractDeclarations(List<String> lines) {
    final decls = <_Decl>[];
    int? braceStart, currentStartLine, depth;
    String? currentName, currentKind;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      if (line.isEmpty || line.startsWith('//') || line.startsWith('@')) {
        if (braceStart != null) {
          for (final ch in line.runes) {
            if (ch == 0x7B) depth = depth! + 1;
            if (ch == 0x7D) depth = depth! - 1;
          }
          if (depth! <= 0) {
            decls.add(_Decl(currentName!, currentKind!, currentStartLine!, i + 1));
            braceStart = null;
          }
        }
        continue;
      }
      if (braceStart == null) {
        final m = _matchDeclaration(line);
        if (m != null) {
          currentName = m.$1;
          currentKind = m.$2;
          currentStartLine = i;
          braceStart = i;
          depth = 0;
        }
      }
      if (braceStart != null) {
        for (final ch in line.runes) {
          if (ch == 0x7B) depth = depth! + 1;
          if (ch == 0x7D) depth = depth! - 1;
        }
        if (depth! <= 0) {
          decls.add(_Decl(currentName!, currentKind!, currentStartLine!, i + 1));
          braceStart = null;
        }
      }
    }
    return decls;
  }

  static (String, String)? _matchDeclaration(String line) {
    var cleaned = line;
    while (cleaned.startsWith('@')) {
      final spaceIdx = cleaned.indexOf(' ');
      if (spaceIdx < 0) return null;
      cleaned = cleaned.substring(spaceIdx + 1).trimLeft();
    }
    final classMatch = RegExp(r'^(abstract\s+|sealed\s+)?class\s+(\$?[A-Za-z_][A-Za-z0-9_$]*)').firstMatch(cleaned);
    if (classMatch != null) return (classMatch.group(2)!, 'class');
    final extMatch = RegExp(r'^extension\s+(\w+)?').firstMatch(cleaned);
    if (extMatch != null) return (extMatch.group(1) ?? '<unnamed>', 'extension');
    final enumMatch = RegExp(r'^enum\s+([A-Za-z_][A-Za-z0-9_]*)').firstMatch(cleaned);
    if (enumMatch != null) return (enumMatch.group(1)!, 'enum');
    final mixinMatch = RegExp(r'^mixin\s+([A-Za-z_][A-Za-z0-9_]*)').firstMatch(cleaned);
    if (mixinMatch != null) return (mixinMatch.group(1)!, 'mixin');
    return null;
  }
}

class _Decl {
  final String name, kind;
  final int startLine, endLine;
  const _Decl(this.name, this.kind, this.startLine, this.endLine);
}
