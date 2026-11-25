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
///    marker, and `.toJson()` becomes `.toWire()`. A `fromWire` result that is
///    consumed as a value gains `.getOrThrow()`; a typed-instance `fromJson`
///    receiver is rewritten to the static `Type.fromWire(map)` call, because
///    the generated member is static (#235, #238).
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
/// untouched. The stale v2 part directives go with it (#249):
/// `PartDirectiveCleaner` strips every `part '*.zorphy.dart';` (v3's shared
/// part is attached by build_runner itself), drops the migrated file's
/// `part '*.g.dart';` unless it declares its own `@JsonSerializable` classes
/// (which get exactly one clean directive back), and reports the removed
/// URIs so the CLI can delete the stale `.zorphy.dart` files under `--apply`.
/// A file with no v2 construct and no stale part is returned byte-for-byte
/// unchanged.
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'part_directive_cleaner.dart';

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
  ///
  /// Names are BARE identifiers matched tree-wide: a package where two files
  /// declare the same class name needs manual review, since an unrelated
  /// `Base` carrying `id` could otherwise classify a local `Base`-derived
  /// child as an entity. A parent declared in the file being transformed
  /// always wins over this global set (see [_hasId]).
  final Set<String> knownEntityRoots;

  /// Direct supertype names per class, keyed by class name, collected across
  /// the WHOLE tree in the CLI's first pass.
  ///
  /// With [knownEntityRoots] alone, classification stops at the first parent
  /// that does not itself declare `id`: `Leaf implements Middle` where
  /// `Middle implements Root` and only `Root` declares `id` leaves `Leaf` a
  /// value. These edges let [V3Codemod] walk that chain transitively (#238).
  /// Bare names are matched tree-wide, with the same collision caveat as
  /// [knownEntityRoots]. Empty by default — only same-file declarations are
  /// walked then.
  final Map<String, List<String>> inheritanceEdges;

  const V3Codemod({
    this.knownTypes = const <String>{},
    this.knownEntityRoots = const <String>{},
    this.inheritanceEdges = const <String, List<String>>{},
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

  /// Direct superclass / mixin / interface names for each class in [source].
  ///
  /// The CLI unions these across the whole tree into
  /// [V3Codemod.inheritanceEdges] so a class inheriting `id` through a parent
  /// in another file is still classified as an entity (#238). An unparseable
  /// file contributes no edges.
  static Map<String, List<String>> inheritanceEdgesIn(String source) {
    final unit = _parse(source);
    if (unit == null) return <String, List<String>>{};
    final edges = <String, List<String>>{};
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        edges[declaration.namePart.typeName.lexeme] = _superTypeNames(
          declaration,
        );
      }
    }
    return edges;
  }

  /// Returns [source] with every v2 construct migrated to v3 and the stale
  /// v2 part directives stripped (#249).
  ///
  /// [fileName] is the library file's own name (`user.dart`); it names the
  /// clean `part '<name>.g.dart';` restored for a file that declares its own
  /// `@JsonSerializable` classes.
  String transform(String source, {String? fileName}) {
    final unit = _parse(source);
    if (unit == null) return source;

    final types = <String>{...knownTypes, ..._zorphyTypes(unit)};
    final classes = _classesIn(unit);
    final variables = _zorphyVariables(unit, types);

    final spans = <_Span>[];
    _collectAnnotations(
      unit,
      classes,
      knownEntityRoots,
      inheritanceEdges,
      spans,
    );
    _collectCodecs(unit, source, types, variables, spans);

    // Spans apply to the ORIGINAL source; the cleaner then re-parses the
    // rewritten text, so its directive offsets stay valid. The json part is
    // stripped only from a file the codemod actually migrated — an unrelated
    // json_serializable file passes through untouched.
    final migrated = spans.isEmpty ? source : _apply(source, spans);
    final cleaned = PartDirectiveCleaner.clean(
      PartDirectiveCleanArg(
        source: migrated,
        libraryFileName: fileName,
        stripJsonParts: spans.isNotEmpty,
      ),
    );
    return cleaned.source;
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

  /// Variables, parameters and fields declared with a zorphy type, mapped to
  /// that type's name. The type is needed to rewrite a typed instance's
  /// `fromJson` into the static `Type.fromWire(...)` call (#238).
  static Map<String, String> _zorphyVariables(
    CompilationUnit unit,
    Set<String> types,
  ) {
    final names = <String, String>{};
    unit.visitChildren(_TypedVariableVisitor(types, names));
    return names;
  }

  /// Rewrites the `@Zorphy` / `@Zorphy2` / `@ZorphySealed` class annotations.
  static void _collectAnnotations(
    CompilationUnit unit,
    Map<String, ClassDeclaration> classes,
    Set<String> knownEntityRoots,
    Map<String, List<String>> inheritanceEdges,
    List<_Span> spans,
  ) {
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      for (final meta in declaration.metadata) {
        final name = meta.name.name;
        String? replacement;
        if (name == 'Zorphy' || name == 'Zorphy2') {
          replacement =
              _classHasId(
                declaration,
                classes,
                knownEntityRoots,
                inheritanceEdges,
              )
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
  /// directly or inherited transitively from a supertype declared in this
  /// file, in another file ([knownEntityRoots]), or reached through
  /// [inheritanceEdges].
  static bool _classHasId(
    ClassDeclaration declaration,
    Map<String, ClassDeclaration> classes,
    Set<String> knownEntityRoots,
    Map<String, List<String>> inheritanceEdges,
  ) => _hasId(
    declaration.namePart.typeName.lexeme,
    classes,
    knownEntityRoots,
    inheritanceEdges,
    <String>{},
  );

  /// Resolve [name] through a declaration in the CURRENT FILE first; only
  /// consult the whole-tree root set / inheritance edges for parents that are
  /// not declared locally. This keeps a same-named global entity from
  /// overriding a local non-entity parent (#238), while [inheritanceEdges]
  /// carries classification transitively through cross-file parents.
  /// [seen] breaks cycles in malformed hierarchies.
  static bool _hasId(
    String name,
    Map<String, ClassDeclaration> classes,
    Set<String> knownEntityRoots,
    Map<String, List<String>> inheritanceEdges,
    Set<String> seen,
  ) {
    if (!seen.add(name)) return false;

    final local = classes[name];
    if (local != null) {
      if (_declaresId(local)) return true;
      for (final parent in _superTypeNames(local)) {
        if (_hasId(parent, classes, knownEntityRoots, inheritanceEdges, seen)) {
          return true;
        }
      }
      return false;
    }

    if (knownEntityRoots.contains(name)) return true;
    for (final parent in inheritanceEdges[name] ?? const <String>[]) {
      if (_hasId(parent, classes, knownEntityRoots, inheritanceEdges, seen)) {
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
    Map<String, String> variables,
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
      final target = call.target;
      if (!_isZorphyCall(target, types, variables)) continue;

      final start = methodName.offset;
      // The generated `fromWire` is STATIC. A call on a typed instance would
      // therefore still fail analysis — rewrite the receiver to its declared
      // type so `codec.fromJson(map)` becomes `Product.fromWire(map)` (#238).
      if (name == 'fromJson' &&
          target is SimpleIdentifier &&
          variables.containsKey(target.name)) {
        spans.add(_Span(target.offset, target.end, variables[target.name]!));
      }
      spans.add(
        _Span(
          start,
          start + name.length,
          name == 'fromJson' ? 'fromWire' : 'toWire',
        ),
      );
      if (name == 'fromJson') {
        // `fromWire` returns `ZorphyBoundaryResult<T>`, not `T`. Append
        // `.getOrThrow()` wherever the result is consumed as a value, so
        // arguments, operands, collection elements and chained access stay
        // type-correct (#235 Case 1, #238). A genuinely discarded call keeps
        // the wrapped result.
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

  /// Whether [call]'s result is consumed as a value, so the
  /// `ZorphyBoundaryResult<T>` must be unwrapped with `.getOrThrow()` to keep
  /// the consumer type-correct (#235, #238).
  ///
  /// Every position is value-consuming except a genuinely DISCARDED call —
  /// a standalone expression statement (optionally parenthesized). An
  /// argument, a binary operand, a conditional branch, a typed collection
  /// element, a chained member access or a parenthesized return all expect a
  /// bare `T` there, so leaving the result wrapped would not type-check.
  static bool _needsUnwrap(MethodInvocation call) {
    AstNode node = call;
    while (true) {
      final parent = node.parent;
      if (parent == null) return true;
      if (parent is ExpressionStatement && parent.expression == node) {
        return false;
      }
      // Parentheses are transparent: `((call));` is still a discarded call.
      if (parent is ParenthesizedExpression) {
        node = parent;
        continue;
      }
      return true;
    }
  }

  /// Whether the receiver is a known zorphy type (static call) or a variable
  /// declared with one (typed instance call). Unknown receivers are untouched.
  static bool _isZorphyCall(
    Expression? target,
    Set<String> types,
    Map<String, String> variables,
  ) {
    if (target is! SimpleIdentifier) return false;
    final name = target.name;
    return types.contains(name) || variables.containsKey(name);
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
/// calls such as `user.toJson()` can be scoped as tightly as static ones and
/// a typed instance's `codec.fromJson(...)` can be rewritten to the static
/// `Type.fromWire(...)` call.
class _TypedVariableVisitor extends RecursiveAstVisitor<void> {
  _TypedVariableVisitor(this.types, this.names);

  final Set<String> types;
  final Map<String, String> names;

  void _record(TypeAnnotation? type, String name) {
    if (type is NamedType && types.contains(type.name.lexeme)) {
      names[name] = type.name.lexeme;
    }
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
