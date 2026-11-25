/// v2 -> v3 AST migration codemod (ISSUE-019, arrrrny/zorphy#194).
///
/// Rewrites a v2 `@Zorphy` / `@Zorphy2` / `@ZorphySealed` codebase onto the
/// zero-preset v3 archetypes:
///
///  - every v2 `preset:` and `generate*` boolean argument is dropped;
///  - `@Zorphy` / `@Zorphy2` on an `id`-bearing class becomes
///    `@ZorphyEntity(principalKey: #id)`, on an `id`-less class `@ZorphyValue()`;
///  - `@ZorphySealed` becomes `@ZorphyUnion`;
///  - `.fromJson(map)` becomes `.fromWire(map)` with a `// TODO(trust-boundary)`
///    marker, and `.toJson()` becomes `.toWire()`.
///
/// Codec rewrites are scoped to zorphy types: a call is migrated only when its
/// receiver is the generated type of a v2-annotated declaration (a `$User`
/// declaration generates the concrete type `User`) or a variable, parameter or
/// field declared with such a type. Type names are discovered in the file being
/// transformed and, when the codemod is driven over a whole tree (as the CLI
/// does), supplied up front via [V3Codemod.knownTypes] so calls in files that
/// do not carry the annotation are still recognised. Unrelated serializers —
/// `json_serializable`, `dart_mappable`, hand-written `fromJson`/`toJson`
/// helpers — are left untouched. A receiver whose zorphy type lives outside
/// the tree being migrated is not detectable and is deliberately left alone.
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
  /// Zorphy type names discovered in OTHER files of the tree being migrated.
  ///
  /// The CLI collects these in a first pass so a codec call in a file that
  /// does not declare the annotated class can still be scoped correctly.
  /// Empty by default — types declared in the file itself are always found.
  final Set<String> knownTypes;

  /// Names of classes that declare an `id` field/getter directly, discovered
  /// across the WHOLE tree in the CLI's first pass.
  ///
  /// A class that inherits `id` from a parent in another file is an entity
  /// too; without this cross-file root set the child would be misclassified as
  /// `@ZorphyValue()` while its parent becomes `@ZorphyEntity(...)` — the
  /// invalid mixed-archetype hierarchy of #235 Case 2. Empty by default, in
  /// which case only same-file inheritance is walked.
  final Set<String> knownEntityRoots;

  const V3Codemod({
    this.knownTypes = const <String>{},
    this.knownEntityRoots = const <String>{},
  });

  /// The trust-boundary marker inserted beside every rewritten `fromWire`.
  static const String trustBoundaryTodo =
      '// TODO(trust-boundary): handle BoundaryErr';

  /// The zorphy-generated type names declared in [source].
  ///
  /// A v2 annotation on `$Foo` generates the concrete type `Foo`. Used by the
  /// CLI's first pass to scope codec rewrites across a whole tree; an
  /// unparseable file contributes no types.
  static Set<String> zorphyTypesIn(String source) {
    final unit = _parse(source);
    return unit == null ? <String>{} : _zorphyTypes(unit);
  }

  /// Names of classes in [source] that declare an `id` field/getter DIRECTLY.
  ///
  /// The CLI unions these across the whole tree into
  /// [V3Codemod.knownEntityRoots] so a class that inherits `id` from a parent
  /// in another file is still classified as an entity (#235 Case 2). An
  /// unparseable file contributes no roots.
  static Set<String> entityRootsIn(String source) {
    final unit = _parse(source);
    if (unit == null) return <String>{};
    final roots = <String>{};
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      if (_declaresId(declaration)) {
        roots.add(declaration.namePart.typeName.lexeme);
      }
    }
    return roots;
  }

  /// Returns [source] with every v2 construct migrated to v3.
  String transform(String source) {
    final unit = _parse(source);
    if (unit == null) return source;

    final types = <String>{...knownTypes, ..._zorphyTypes(unit)};
    final classes = _classesIn(unit);
    final variables = _zorphyVariables(unit, types);

    final spans = <_Span>[];
    _collectAnnotations(unit, classes, knownEntityRoots, spans);
    _collectCodecs(unit, source, types, variables, spans);

    if (spans.isEmpty) return source;
    return _apply(source, spans);
  }

  static CompilationUnit? _parse(String source) {
    try {
      return parseString(content: source).unit;
    } on ArgumentError {
      // An unparseable file is left untouched — never edit blind.
      return null;
    }
  }

  /// The concrete type name a v2 declaration generates (`$User` -> `User`).
  static String _generatedName(String declarationName) =>
      declarationName.startsWith(r'$')
      ? declarationName.substring(1)
      : declarationName;

  /// Every class declared in [unit], keyed by its declared name.
  static Map<String, ClassDeclaration> _classesIn(CompilationUnit unit) {
    final classes = <String, ClassDeclaration>{};
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        classes[declaration.namePart.typeName.lexeme] = declaration;
      }
    }
    return classes;
  }

  /// Whether [declaration] declares an `id` field or getter DIRECTLY (not
  /// inherited). Used to build the whole-tree entity-root set.
  static bool _declaresId(ClassDeclaration declaration) {
    for (final member in declaration.body.members) {
      if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          if (variable.name.lexeme == 'id') return true;
        }
      } else if (member is MethodDeclaration &&
          member.isGetter &&
          member.name.lexeme == 'id') {
        return true;
      }
    }
    return false;
  }

  /// Type names generated by the v2 annotations declared in [unit].
  static Set<String> _zorphyTypes(CompilationUnit unit) {
    final types = <String>{};
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      for (final meta in declaration.metadata) {
        final name = meta.name.name;
        if (name == 'Zorphy' || name == 'Zorphy2' || name == 'ZorphySealed') {
          types.add(_generatedName(declaration.namePart.typeName.lexeme));
        }
      }
    }
    return types;
  }

  /// Names of variables, parameters and fields declared with a zorphy type.
  static Set<String> _zorphyVariables(CompilationUnit unit, Set<String> types) {
    final names = <String>{};
    unit.visitChildren(_TypedVariableVisitor(types, names));
    return names;
  }

  /// Rewrites the `@Zorphy` / `@Zorphy2` / `@ZorphySealed` class annotations.
  static void _collectAnnotations(
    CompilationUnit unit,
    Map<String, ClassDeclaration> classes,
    Set<String> knownEntityRoots,
    List<_Span> spans,
  ) {
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      for (final meta in declaration.metadata) {
        final name = meta.name.name;
        String? replacement;
        if (name == 'Zorphy' || name == 'Zorphy2') {
          replacement = _classHasId(declaration, classes, knownEntityRoots)
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

  /// Whether [declaration] has a field (or getter) named `id`, declared
  /// directly or inherited from a supertype / mixin declared in this file or,
  /// via [knownEntityRoots], in another file of the tree being migrated.
  static bool _classHasId(
    ClassDeclaration declaration,
    Map<String, ClassDeclaration> classes,
    Set<String> knownEntityRoots, [
    Set<String>? seen,
  ]) {
    seen ??= <String>{};
    if (!seen.add(declaration.namePart.typeName.lexeme)) return false;

    if (_declaresId(declaration)) return true;

    // An `id` inherited from a superclass, mixin or interface still makes the
    // class an entity. A parent in another file is resolved through the
    // whole-tree [knownEntityRoots] set (#235 Case 2); a parent in this file
    // recurses through its real declaration.
    for (final parentName in _superTypeNames(declaration)) {
      if (knownEntityRoots.contains(parentName)) return true;
      final parent = classes[parentName];
      if (parent != null &&
          _classHasId(parent, classes, knownEntityRoots, seen)) {
        return true;
      }
    }
    return false;
  }

  static List<String> _superTypeNames(ClassDeclaration declaration) {
    final names = <String>[];
    final extendsClause = declaration.extendsClause;
    if (extendsClause != null) names.add(extendsClause.superclass.name.lexeme);
    final withClause = declaration.withClause;
    if (withClause != null) {
      for (final mixin in withClause.mixinTypes) names.add(mixin.name.lexeme);
    }
    final implementsClause = declaration.implementsClause;
    if (implementsClause != null) {
      for (final type in implementsClause.interfaces) {
        names.add(type.name.lexeme);
      }
    }
    return names;
  }

  /// Rewrites zorphy `.fromJson(...)` / `.toJson()` call sites to wire codecs.
  static void _collectCodecs(
    CompilationUnit unit,
    String source,
    Set<String> types,
    Set<String> variables,
    List<_Span> spans,
  ) {
    final visitor = _CodecVisitor();
    unit.visitChildren(visitor);

    // One trust-boundary TODO per physical line, indented like the call it
    // guards. De-duplicating stops two codecs on one line stacking comments.
    final todoLines = <int>{};
    for (final call in visitor.calls) {
      final methodName = call.methodName;
      final name = methodName.name;
      if (name != 'fromJson' && name != 'toJson') continue;
      if (!_isZorphyCall(call.target, types, variables)) continue;

      final start = methodName.offset;
      spans.add(
        _Span(
          start,
          start + name.length,
          name == 'fromJson' ? 'fromWire' : 'toWire',
        ),
      );
      if (name == 'fromJson') {
        // `fromWire` returns `ZorphyBoundaryResult<T>`, not `T`. When the call
        // sits in a context that expects the bare value (a returned or
        // assigned expression), append `.getOrThrow()` so the migrated
        // consumer still compiles (#235 Case 1). A bare-expression call has no
        // type to preserve and keeps the result as-is.
        if (_needsUnwrap(call)) {
          final end = call.offset + call.length;
          spans.add(_Span(end, end, '.getOrThrow()'));
        }
        final lineStart = _lineStart(source, call.offset);
        if (todoLines.add(lineStart)) {
          spans.add(
            _Span(
              lineStart,
              lineStart,
              '${_indentOf(source, lineStart)}$trustBoundaryTodo\n',
            ),
          );
        }
      }
    }
  }

  /// Whether [call]'s result is consumed as a bare value — a `return` or an
  /// assignment RHS — so the `BoundaryResult` must be unwrapped with
  /// `.getOrThrow()` to keep the consumer type-correct (#235 Case 1).
  static bool _needsUnwrap(MethodInvocation call) {
    final parent = call.parent;
    if (parent is ReturnStatement) return true;
    // Arrow form `=> expr` is an ExpressionFunctionBody, not a ReturnStatement.
    if (parent is ExpressionFunctionBody) return true;
    if (parent is AssignmentExpression && parent.rightHandSide == call) {
      return true;
    }
    if (parent is VariableDeclaration && parent.initializer == call) {
      return true;
    }
    return false;
  }

  /// Whether the receiver is a known zorphy type (static call) or a variable
  /// declared with one (instance call). Unknown receivers are left untouched.
  static bool _isZorphyCall(
    Expression? target,
    Set<String> types,
    Set<String> variables,
  ) {
    if (target is! SimpleIdentifier) return false;
    final name = target.name;
    return types.contains(name) || variables.contains(name);
  }

  static int _lineStart(String source, int offset) {
    final idx = source.lastIndexOf('\n', offset - 1);
    return idx < 0 ? 0 : idx + 1;
  }

  /// Leading whitespace of the line starting at [lineStart].
  static String _indentOf(String source, int lineStart) {
    var i = lineStart;
    while (i < source.length) {
      final codeUnit = source.codeUnitAt(i);
      if (codeUnit != 0x20 && codeUnit != 0x09) break;
      i++;
    }
    return source.substring(lineStart, i);
  }

  static String _apply(String source, List<_Span> spans) {
    final sorted = [...spans]..sort((a, b) => b.start.compareTo(a.start));
    var result = source;
    for (final span in sorted) {
      result = result.replaceRange(span.start, span.end, span.text);
    }
    return result;
  }
}

/// Collects every `.<method>(...)` invocation so codec calls can be filtered
/// by receiver type.
class _CodecVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    calls.add(node);
    node.visitChildren(this);
  }
}

/// Records variables whose declared type is a known zorphy type, so instance
/// calls such as `user.toJson()` can be scoped as tightly as static ones.
class _TypedVariableVisitor extends RecursiveAstVisitor<void> {
  _TypedVariableVisitor(this.types, this.names);

  final Set<String> types;
  final Set<String> names;

  void _record(TypeAnnotation? type, String name) {
    if (type is NamedType && types.contains(type.name.lexeme)) names.add(name);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    for (final variable in node.variables) {
      _record(node.type, variable.name.lexeme);
    }
    super.visitVariableDeclarationList(node);
  }

  void _recordParameter(FormalParameter node) {
    final name = node.name;
    if (name != null) _record(node.type, name.lexeme);
  }

  // analyzer 14.7 dispatches concrete parameters through these three hooks,
  // not the abstract `visitFormalParameter`.
  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    _recordParameter(node);
    node.visitChildren(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _recordParameter(node);
    node.visitChildren(this);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _recordParameter(node);
    node.visitChildren(this);
  }
}
