/// v2 -> v3 AST migration codemod (ISSUE-019, arrrrny/zorphy#194).
///
/// Rewrites a v2 `@Zorphy` / `@ZorphySealed` codebase onto the zero-preset v3
/// archetypes:
///
///  - every v2 `preset:` and `generate*` boolean argument is dropped;
///  - `@Zorphy` on an `id`-bearing class becomes `@ZorphyEntity(principalKey:
///    #id)`, on an `id`-less class `@ZorphyValue()`;
///  - `@ZorphySealed` becomes `@ZorphyUnion`;
///  - `.fromJson(map)` becomes `.fromWire(map)` with a `// TODO(trust-boundary)`
///    marker, and `.toJson()` becomes `.toWire()`.
///
/// The transform is span-based over the analyzer's parse tree (the same
/// approach `zorphy_migrator` uses): only the matched annotation / method-name
/// spans are replaced, so file order, comments and unrelated code survive
/// untouched. A file with no v2 construct is returned byte-for-byte unchanged.
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// One source-span replacement (`[start, end)` -> [text]).
class _Span {
  final int start;
  final int end;
  final String text;

  const _Span(this.start, this.end, this.text);
}

/// The v2 -> v3 rewriter.
class V3Codemod {
  const V3Codemod();

  /// The trust-boundary marker inserted beside every rewritten `fromWire`.
  static const String trustBoundaryTodo =
      '// TODO(trust-boundary): handle BoundaryErr';

  /// Returns [source] with every v2 construct migrated to v3.
  String transform(String source) {
    final CompilationUnit unit;
    try {
      unit = parseString(content: source).unit;
    } on ArgumentError {
      // An unparseable file is left untouched — never edit blind.
      return source;
    }

    final spans = <_Span>[];
    _collectAnnotations(unit, spans);
    _collectCodecs(unit, source, spans);

    if (spans.isEmpty) return source;
    return _apply(source, spans);
  }

  /// Rewrites the `@Zorphy` / `@Zorphy2` / `@ZorphySealed` class annotations.
  void _collectAnnotations(CompilationUnit unit, List<_Span> spans) {
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      for (final meta in declaration.metadata) {
        final name = meta.name.name;
        String? replacement;
        if (name == 'Zorphy' || name == 'Zorphy2') {
          replacement = _classHasId(declaration)
              ? '@ZorphyEntity(principalKey: #id)'
              : '@ZorphyValue()';
        } else if (name == 'ZorphySealed') {
          replacement = '@ZorphyUnion()';
        }
        if (replacement != null) {
          spans.add(_Span(meta.offset, meta.end, replacement));
        }
      }
    }
  }

  /// Whether [declaration] declares a field (or getter) named `id`.
  bool _classHasId(ClassDeclaration declaration) {
    for (final member in declaration.body.members) {
      if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          if (variable.name.lexeme == 'id') return true;
        }
      } else if (member is MethodDeclaration && member.isGetter) {
        if (member.name.lexeme == 'id') return true;
      }
    }
    return false;
  }

  /// Rewrites `.fromJson(...)` / `.toJson()` call sites to their wire codecs.
  void _collectCodecs(CompilationUnit unit, String source, List<_Span> spans) {
    final visitor = _CodecVisitor();
    unit.visitChildren(visitor);
    for (final call in visitor.calls) {
      final methodName = call.methodName;
      final name = methodName.name;
      if (name == 'fromJson') {
        // Rename the method, then mark the line for the trust boundary.
        final start = methodName.offset;
        spans.add(_Span(start, start + name.length, 'fromWire'));
        final lineStart = _lineStart(source, call.offset);
        spans.add(_Span(lineStart, lineStart, '$trustBoundaryTodo\n'));
      } else if (name == 'toJson') {
        final start = methodName.offset;
        spans.add(_Span(start, start + name.length, 'toWire'));
      }
    }
  }

  int _lineStart(String source, int offset) {
    final idx = source.lastIndexOf('\n', offset - 1);
    return idx < 0 ? 0 : idx + 1;
  }

  String _apply(String source, List<_Span> spans) {
    final sorted = [...spans]..sort((a, b) => b.start.compareTo(a.start));
    var result = source;
    for (final span in sorted) {
      result = result.replaceRange(span.start, span.end, span.text);
    }
    return result;
  }
}

/// Collects every `.<method>(...)` invocation whose name is a v2 codec.
class _CodecVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    calls.add(node);
    node.visitChildren(this);
  }
}
