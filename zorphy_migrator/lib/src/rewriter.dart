import 'model.dart';

/// Applies source-span replacements and produces unified diffs.
///
/// Only annotated class spans are replaced — file order, comments, and
/// unrelated code are preserved by construction (spans applied in reverse
/// offset order over the original source).
class Rewriter {
  /// Applies [replacements] (spanEnd-exclusive) to [source].
  String applySpans(String source, List<SpanReplacement> replacements) {
    final sorted = [...replacements]
      ..sort((a, b) => b.start.compareTo(a.start)); // reverse offset order
    var result = source;
    for (final r in sorted) {
      result = result.replaceRange(r.start, r.end, r.replacement);
    }
    return result;
  }

  /// Produces a unified diff between [original] and [revised]
  /// (LCS-based, 3 lines of context).
  String unifiedDiff(String original, String revised, String path) {
    final a = original.split('\n');
    final b = revised.split('\n');
    final hunks = _hunks(a, b);
    if (hunks.isEmpty) return '';

    final sb = StringBuffer()
      ..writeln('--- a/$path')
      ..writeln('+++ b/$path');
    for (final hunk in hunks) {
      sb.write(hunk);
    }
    return sb.toString();
  }

  List<String> _hunks(List<String> a, List<String> b) {
    final table = _lcsTable(a, b);
    final ops = <_DiffOp>[];
    var i = 0, j = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        ops.add(_DiffOp(' ', a[i], i + 1, j + 1));
        i++;
        j++;
      } else if (table[i + 1][j] >= table[i][j + 1]) {
        ops.add(_DiffOp('-', a[i], i + 1, null));
        i++;
      } else {
        ops.add(_DiffOp('+', b[j], null, j + 1));
        j++;
      }
    }
    while (i < a.length) {
      ops.add(_DiffOp('-', a[i], i + 1, null));
      i++;
    }
    while (j < b.length) {
      ops.add(_DiffOp('+', b[j], null, j + 1));
      j++;
    }

    // Group into hunks with 3 lines of context.
    const context = 3;
    final hunks = <String>[];
    var idx = 0;
    while (idx < ops.length) {
      // Find next change.
      var changeIdx = idx;
      while (changeIdx < ops.length && ops[changeIdx].tag == ' ') {
        changeIdx++;
      }
      if (changeIdx == ops.length) break;

      final start = (changeIdx - context) > idx ? changeIdx - context : idx;
      var end = changeIdx;
      var lastChange = changeIdx;
      while (end < ops.length) {
        if (ops[end].tag != ' ') {
          lastChange = end;
        } else if (end - lastChange > 2 * context) {
          break;
        }
        end++;
      }
      final stop = (lastChange + context + 1) < end
          ? lastChange + context + 1
          : end;

      final slice = ops.sublist(start, stop);
      final oldStart = slice.firstWhere((o) => o.oldLine != null,
          orElse: () => slice.first);
      final newStart = slice.firstWhere((o) => o.newLine != null,
          orElse: () => slice.first);
      final oldCount = slice.where((o) => o.tag != '+').length;
      final newCount = slice.where((o) => o.tag != '-').length;

      final sb = StringBuffer()
        ..writeln(
          '@@ -${oldStart.oldLine ?? 1},$oldCount '
          '+${newStart.newLine ?? 1},$newCount @@',
        );
      for (final op in slice) {
        sb.writeln('${op.tag}${op.text}');
      }
      hunks.add(sb.toString());
      idx = stop;
    }
    return hunks;
  }

  List<List<int>> _lcsTable(List<String> a, List<String> b) {
    final table = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );
    for (var i = a.length - 1; i >= 0; i--) {
      for (var j = b.length - 1; j >= 0; j--) {
        table[i][j] = a[i] == b[j]
            ? table[i + 1][j + 1] + 1
            : (table[i + 1][j] > table[i][j + 1]
                ? table[i + 1][j]
                : table[i][j + 1]);
      }
    }
    return table;
  }
}

/// A single span replacement over the original source.
class SpanReplacement {
  final int start;
  final int end;
  final String replacement;

  const SpanReplacement(this.start, this.end, this.replacement);
}

class _DiffOp {
  final String tag; // ' ', '-', '+'
  final String text;
  final int? oldLine;
  final int? newLine;

  _DiffOp(this.tag, this.text, this.oldLine, this.newLine);
}

/// Builds the list of span replacements for a file's detected models.
List<SpanReplacement> replacementsFor(
  List<FreezedClassModel> models,
  String Function(FreezedClassModel) render,
) {
  return [
    for (final m in models.where((m) => m.isMigratable))
      SpanReplacement(m.spanStart, m.spanEnd, render(m)),
  ];
}
