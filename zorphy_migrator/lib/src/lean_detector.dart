import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'rewriter.dart';

/// Identifiers found per file, keyed by path, with occurrence counts.
typedef SymbolIndex = Map<String, Map<String, int>>;

/// One generated feature a class may or may not actually use.
enum LeanFeature {
  patch('generatePatch', 'Patch', false),
  filter('generateFilter', 'Filter', false),
  copyWithFn('generateCopyWithFn', 'CopyWithFn', true),
  json('generateJson', 'Json', true);

  /// The `@Zorphy` field that turns this feature on.
  final String annotationField;

  /// Infix used in the generated symbol names for this feature.
  final String symbolInfix;

  /// Whether the feature is reached through an instance call.
  ///
  /// `foo.toJson()` and `foo.copyWithFn(...)` name no class, so a syntactic
  /// scan cannot attribute their use. Such a feature is only dropped for a
  /// class nothing else in the target references.
  final bool instanceLevel;

  const LeanFeature(this.annotationField, this.symbolInfix, this.instanceLevel);

  /// Symbols whose presence proves [this] feature is used by `className`.
  ///
  /// Zorphy names generated helpers after the class, so these are
  /// class-attributed: a hit means THIS class's feature is consumed, not
  /// merely that the feature exists somewhere in the package.
  List<String> symbolsFor(String className) => switch (this) {
    LeanFeature.patch => ['${className}Patch', 'patchWith$className'],
    LeanFeature.filter => ['${className}Fields', '${className}Field'],
    LeanFeature.copyWithFn => [
      'copyWith${className}Fn',
      '${className}CopyWithFn',
    ],
    LeanFeature.json => [
      '${className}FromJson',
      '_$className'
          'FromJson',
      '_\$${className}FromJson',
    ],
  };
}

/// A `@Zorphy`/`@Zorphy2` class and the leaner annotation that still covers
/// everything the package actually consumes.
class LeanProposal {
  final String filePath;

  /// Absolute offset of the annotation's `@` in [filePath].
  final int offset;

  /// End offset of the annotation expression.
  final int end;

  final String className;
  final String currentSource;

  /// Features referenced somewhere under the scanned target.
  final Set<LeanFeature> used;

  /// Features the current annotation explicitly asks for.
  final Set<LeanFeature> declared;

  /// Whether the class is referenced from anywhere else in the target.
  ///
  /// A live class is never downgraded to `lean`: its `changeTo`, `compareTo`,
  /// `copyWithFn` and `toJson` are instance calls, and this detector does not
  /// resolve receiver types, so it cannot tell whether they are used. The
  /// project compiles today, so a live class keeps the preset its author chose
  /// and only loses opt-in flags it can prove unused.
  final bool isLive;

  /// Named arguments to carry over verbatim (`autoId`, `kind`, …).
  final List<String> preservedArgs;

  /// The `preset:` argument's source text, when the annotation has one.
  final String? presetArg;

  const LeanProposal({
    required this.filePath,
    required this.offset,
    required this.end,
    required this.className,
    required this.currentSource,
    required this.used,
    required this.declared,
    required this.isLive,
    required this.preservedArgs,
    required this.presetArg,
  });

  /// True when the class already carries the leanest sufficient annotation.
  bool get alreadyLean =>
      declared.difference(used).isEmpty && (isLive || presetIsLean);

  /// Whether the annotation pins the `lean` preset explicitly.
  bool get presetIsLean => presetArg?.contains('ZorphyPreset.lean') ?? false;

  /// The replacement annotation text.
  ///
  /// Only ever removes: a feature flag is emitted when the annotation already
  /// asked for it and the detector could prove it is used. A live class keeps
  /// its preset untouched, so a proposal never adds a feature or a preset the
  /// author did not choose.
  String get proposedSource {
    final args = <String>[
      if (!isLive)
        'preset: ZorphyPreset.lean'
      else if (presetArg != null)
        presetArg!,
    ];
    for (final feature in LeanFeature.values) {
      if (declared.contains(feature) && used.contains(feature)) {
        args.add('${feature.annotationField}: true');
      }
    }
    args.addAll(preservedArgs);
    return '@Zorphy(${args.join(', ')})';
  }
}

/// Decides, per annotated class, which generated features can be dropped.
///
/// Scans a whole target for `@Zorphy`/`@Zorphy2` annotations, then checks
/// whether each class's generated helpers are referenced anywhere in the
/// same target. A feature with no reference is omitted from the proposed
/// annotation, so the generator stops emitting it.
///
/// Conservative by construction: only class-attributed symbol names count as
/// evidence of use, and any ambiguity keeps the feature.
class LeanDetector {
  /// Files that could not be parsed and were therefore left untouched.
  ///
  /// A real tree is not always parseable — a single exotic parameter modifier
  /// is enough — and one bad file must not abort a 150-class scan. Skipping is
  /// the safe direction: no annotation in a skipped file is proposed for a
  /// change, so the run under-proposes rather than editing blind.
  final List<String> skippedFiles = [];

  /// Finds one proposal per annotated class in [filePaths].
  ///
  /// Syntactic only — annotations are recognised by name and their offsets
  /// taken straight from the parse, so a package the size of zik_zak is
  /// scanned in seconds rather than the minutes full resolution costs.
  /// [symbols] is the index from [collectSymbols] over the same files.
  Future<List<LeanProposal>> detect(
    List<String> filePaths, {
    required SymbolIndex symbols,
  }) async {
    final proposals = <LeanProposal>[];
    final usedSymbols = symbols.values.fold(<String>{}, (all, counts) {
      all.addAll(counts.keys);
      return all;
    });
    for (final file in filePaths) {
      final source = await File(file).readAsString();
      final CompilationUnit unit;
      try {
        unit = parseString(content: source, path: file).unit;
      } on ArgumentError {
        skippedFiles.add(file);
        continue;
      }
      _collectProposals(unit, file, source, usedSymbols, symbols, proposals);
    }
    return proposals;
  }

  void _collectProposals(
    CompilationUnit unit,
    String filePath,
    String source,
    Set<String> usedSymbols,
    SymbolIndex symbols,
    List<LeanProposal> proposals,
  ) {
    for (final declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      final annotation = _zorphyAnnotation(declaration);
      if (annotation == null) continue;

      // `declaredFragment` is only populated by the resolver, which this
      // detector deliberately avoids; the name token sits right after the
      // `class` keyword in the parse tree.
      final declaredName = declaration.classKeyword.next?.lexeme;
      if (declaredName == null) continue;

      // Zorphy's convention: `@Zorphy abstract class $Foo` generates `Foo`.
      // Every generated helper is named after the post-`$` identifier, so
      // that is the name feature detection must match against.
      final className = declaredName.startsWith('\$')
          ? declaredName.substring(1)
          : declaredName;
      final live = _isLive(
        className,
        filePath,
        symbols,
        declaredWithDollar: declaredName.startsWith('\$'),
      );
      final used = <LeanFeature>{
        for (final feature in LeanFeature.values)
          if (_featureUsed(
            feature,
            className,
            filePath,
            live,
            usedSymbols,
            symbols,
          ))
            feature,
      };

      final declared = <LeanFeature>{
        for (final feature in LeanFeature.values)
          if (RegExp('${feature.annotationField}\\s*:\\s*true')
              .hasMatch(source.substring(annotation.offset, annotation.end)))
            feature,
      };

      proposals.add(
        LeanProposal(
          filePath: filePath,
          offset: annotation.offset,
          end: annotation.end,
          className: className,
          currentSource: source.substring(annotation.offset, annotation.end),
          used: used,
          declared: declared,
          isLive: live,
          preservedArgs: _preservedArgs(annotation),
          presetArg: _presetArg(annotation),
        ),
      );
    }
  }

  /// Whether [className] is referenced from anywhere beyond its declaration.
  ///
  /// Both spellings count: hand-written code uses the generated `Foo`, while
  /// zorphy's own annotations and field types use `$Foo`. A `$Foo`
  /// declaration never spells its own plain name, so one plain `Foo` in the
  /// declaring file is already a real use; a plain `Foo` class counts itself
  /// once, so it takes two.
  bool _isLive(
    String className,
    String declaringFile,
    SymbolIndex symbols, {
    required bool declaredWithDollar,
  }) {
    final declaredIn = symbols[declaringFile];
    if ((declaredIn?['\$$className'] ?? 0) > 1) return true;
    final ownName = declaredIn?[className] ?? 0;
    if (declaredWithDollar ? ownName >= 1 : ownName > 1) return true;
    // A helper of this class named in another file (`FooPatch`, `FooFields`)
    // is as good as its own name: someone is using the class.
    final helpers = {
      for (final feature in LeanFeature.values)
        ...feature.symbolsFor(className),
    };
    // Same library: a helper named here means this file consumes the class,
    // and a same-file `toJson()` is exactly what a syntactic scan cannot see.
    final declaredHere = declaredIn?.keys.toSet() ?? const <String>{};
    if (helpers.any(declaredHere.contains)) return true;
    return symbols.entries.any(
      (entry) =>
          entry.key != declaringFile &&
          (entry.value.containsKey(className) ||
              entry.value.containsKey('\$$className') ||
              helpers.any(entry.value.containsKey)),
    );
  }

  /// Named arguments other than the preset and the four feature flags.
  List<String> _preservedArgs(Annotation annotation) => [
    for (final arg in annotation.arguments?.arguments ?? const <AstNode>[])
      if (arg is NamedArgument &&
          !_featureFields.contains(arg.name.lexeme) &&
          arg.name.lexeme != 'preset')
        '${arg.name.lexeme}: ${arg.argumentExpression.toSource()}',
  ];

  /// The `preset:` argument's source text, if the annotation carries one.
  String? _presetArg(Annotation annotation) {
    for (final arg in annotation.arguments?.arguments ?? const <AstNode>[]) {
      if (arg is NamedArgument && arg.name.lexeme == 'preset') {
        return 'preset: ${arg.argumentExpression.toSource()}';
      }
    }
    return null;
  }

  static final _featureFields = {
    for (final feature in LeanFeature.values) feature.annotationField,
  };

  /// The `@Zorphy`/`@Zorphy2` annotation node on [declaration], if any.
  Annotation? _zorphyAnnotation(ClassDeclaration declaration) {
    for (final meta in declaration.metadata) {
      final name = meta.name.name;
      if (name == 'Zorphy' || name == 'Zorphy2') return meta;
    }
    return null;
  }

  /// Whether [feature] is consumed for [className] declared in [declaringFile].
  ///
  /// Patch and filter helpers are named after the class (`FooPatch`, `FooFields`),
  /// so a plain identifier hit is class-attributed and trustworthy. JSON and
  /// copyWithFn are reached through instance calls (`foo.toJson()`,
  /// `foo.copyWithFn(...)`) whose receiver type this detector does not resolve,
  /// so they are only dropped for a class nothing else in the target mentions.
  bool _featureUsed(
    LeanFeature feature,
    String className,
    String declaringFile,
    bool live,
    Set<String> usedSymbols,
    SymbolIndex symbols,
  ) {
    if (feature.symbolsFor(className).any(usedSymbols.contains)) return true;
    if (!feature.instanceLevel) return false;
    return live;
  }

  /// Every identifier appearing in each of [filePaths], with per-file counts.
  ///
  /// Deliberately syntactic rather than resolved: resolving a package the
  /// size of zik_zak costs minutes, while this scans it in seconds. The
  /// over-approximation is the safe direction — a generated helper name
  /// mentioned only in a comment still keeps that feature, and the tool never
  /// deletes code on a technicality.
  static Future<SymbolIndex> collectSymbols(List<String> filePaths) async {
    final index = <String, Map<String, int>>{};
    for (final file in filePaths) {
      final text = await File(file).readAsString();
      final counts = <String, int>{};
      for (final match in _identifier.allMatches(text)) {
        final word = match.group(0)!;
        counts[word] = (counts[word] ?? 0) + 1;
      }
      index[file] = counts;
    }
    return index;
  }

  static final _identifier = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');
}

/// Spans that replace each proposal's annotation with its leaner form.
List<SpanReplacement> leanReplacements(List<LeanProposal> proposals) => [
  for (final proposal in proposals)
    if (!proposal.alreadyLean)
      SpanReplacement(proposal.offset, proposal.end, proposal.proposedSource),
];
