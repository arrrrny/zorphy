import 'package:code_builder/code_builder.dart';

import '../analysis/class_analyzer.dart';
import '../ast/ast.dart';
import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates compareTo extension method.
///
/// Produces a native [Extension] spec.
///
/// Honors `GenerationConfig.equalityExcludes` (issue #127): fields whose
/// Dart name is listed in `equalityExcludes` are skipped — they do NOT
/// appear as entries in the returned `diff` map. Without this filter, an
/// `autoId` entity would always report a spurious `id` diff for two
/// freshly-constructed instances with identical field values.
class CompareToExtensionGenerator extends ConcreteClassGenerator {
  CompareToExtensionGenerator();

  @override
  bool shouldGenerate(GenerationContext context) =>
      context.config.generateCompareTo;

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final excludes = context.config.equalityExcludes.toSet();
    final fields = excludes.isEmpty
        ? metadata.allFields
        : metadata.allFields.where((f) => !excludes.contains(f.name)).toList();
    return [_buildCompareToExtension(metadata.cleanName, fields)];
  }

  Extension _buildCompareToExtension(
    String classNameTrimmed,
    List<dynamic> allFields,
  ) {
    final body = <String>[];
    body.add('final Map<String, dynamic> diff = {};');
    for (final field in allFields) {
      final fieldType = field.type ?? '';
      final fieldName = field.name;
      if (fieldType.contains('Function')) continue;
      body.add('');
      body.add("if ($fieldName != other.$fieldName) {");
      body.add("  diff['$fieldName'] = () => other.$fieldName;");
      body.add('}');
    }
    body.add('return diff;');
    return Extension((e) {
      e.name = '${classNameTrimmed}CompareE';
      e.on = referType(classNameTrimmed);
      e.methods.add(
        Method((m) {
          m.name = 'compareTo${classNameTrimmed}';
          m.returns = referType('Map<String, dynamic>');
          m.requiredParameters.add(
            Parameter((p) {
              p.name = 'other';
              p.type = referType(classNameTrimmed);
            }),
          );
          m.body = Code(body.join('\n'));
        }),
      );
    });
  }
}

/// Generates changeTo extension methods for explicit subtypes.
///
/// Produces a native [Extension] spec.
///
/// A `changeTo<Subtype>` body is a JSON round-trip: it collects the runtime
/// subtype's `toJson()`, overlays the patch's `toJson()`, and rebuilds the
/// target with `fromJson`. Those members exist only on a class generated with
/// `generateJson: true`, so the extension is withheld unless the JSON surface
/// it calls is really there (issue #159) — otherwise a hierarchy that never
/// asked for JSON gets a part file that does not compile.
class ChangeToExtensionGenerator extends UniversalGenerator {
  ChangeToExtensionGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    if (!context.config.generateChangeTo) return false;
    final metadata = context.metadata;
    if (metadata.explicitSubtypes.isEmpty) return false;
    return _jsonSurfaceExists(context);
  }

  /// Whether every type the generated bodies call has a JSON surface.
  ///
  /// The switch dispatches on the *runtime* subtype, so each declared subtype
  /// needs its own `toJson()` and `fromJson`. A base that is not sealed also
  /// needs its own `toJson()`, because its `switch` carries a
  /// `_ => this.toJson()` default — see [_hasBaseCase].
  bool _jsonSurfaceExists(GenerationContext context) {
    final metadata = context.metadata;
    if (!metadata.isSealed && !_hasBaseCase(context)) return false;
    for (final subtype in metadata.explicitSubtypes) {
      final element = metadata.allAnnotatedClasses[subtype.interfaceName];
      // An unresolvable subtype is not evidence that its JSON surface exists.
      if (element == null) return false;
      if (!ClassAnalyzer.generatesJson(element)) return false;
    }
    return true;
  }

  /// Whether the generated `switch` carries a `_ => this.toJson()` default —
  /// and the base declares the `toJson()` that default calls.
  ///
  /// A `sealed` base needs no default: its switch is exhaustive over the
  /// declared subtypes. Any other base is not — a plain `$` base, an undeclared
  /// closure, or a subtype declared in another library (#142, where sealing is
  /// deliberately withheld) — and its default calls `toJson()` on the base,
  /// which `JsonGenerator` emits only for a `nonSealed` base. A base that
  /// declares `explicitSubTypes` never gets one from `JsonExtensionGenerator`,
  /// whose `shouldGenerate` skips any class that declares subtypes. So the
  /// base case exists exactly when JSON is on AND the base is `nonSealed`.
  ///
  /// The gate and the emitter both read this, so a base without a `toJson()`
  /// can neither pass the gate nor get a default case that calls it.
  static bool _hasBaseCase(GenerationContext context) =>
      !context.metadata.isSealed &&
      context.config.generateJson &&
      context.metadata.nonSealed;

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    if (metadata.explicitSubtypes.isEmpty) return [];
    final knownClasses = metadata.allAnnotatedClasses.keys
        .map((k) => k.replaceAll(r'\$', ''))
        .toList();
    return [
      _buildChangeToExtension(
        sourceFields: metadata.allFields,
        sourceClassName: metadata.cleanName,
        explicitSubTypes: metadata.explicitSubtypes,
        knownClasses: knownClasses,
        baseCase: _hasBaseCase(context),
      ),
    ];
  }

  Extension _buildChangeToExtension({
    required List<dynamic> sourceFields,
    required String sourceClassName,
    required List<dynamic> explicitSubTypes,
    required List<String> knownClasses,
    required bool baseCase,
  }) {
    final sourceClassNameTrimmed = sourceClassName.replaceAll(r'\$', '');
    final methods = <Method>[];

    for (final targetInterface in explicitSubTypes) {
      final targetClassName = targetInterface.interfaceName.replaceAll(
        r'$',
        '',
      );
      final targetFields = targetInterface.fields;
      final targetFieldsDistinct = <dynamic>[];
      final targetFieldNames = <String>{};
      for (final field in targetFields) {
        if (targetFieldNames.add(field.name)) targetFieldsDistinct.add(field);
      }

      final sourceFieldMap = {for (final f in sourceFields) f.name: f};
      final params = <Parameter>[];
      final setFieldNames = <String, bool>{};

      for (final field in targetFieldsDistinct) {
        final fieldName = field.name;
        final fieldType = helpers.replaceDollarTypesWithConcrete(
          field.type ?? '',
        );
        final isTargetNullable = fieldType.endsWith('?');
        final existsInSource = sourceFieldMap.containsKey(fieldName);

        if (existsInSource) {
          final sourceField = sourceFieldMap[fieldName]!;
          final sourceFieldType = helpers.replaceDollarTypesWithConcrete(
            sourceField.type ?? '',
          );
          final isSourceNullable = sourceFieldType.endsWith('?');

          if (isSourceNullable && !isTargetNullable) {
            params.add(
              Parameter((p) {
                p.name = fieldName;
                p.type = referType(fieldType);
                p.required = true;
                p.named = true;
              }),
            );
            setFieldNames[fieldName] = true;
          } else if (isTargetNullable) {
            params.add(
              Parameter((p) {
                p.name = fieldName;
                p.type = referType(fieldType);
                p.named = true;
              }),
            );
            setFieldNames[fieldName] = false;
          } else {
            params.add(
              Parameter((p) {
                p.name = fieldName;
                p.type = referType('${fieldType}?');
                p.named = true;
              }),
            );
            setFieldNames[fieldName] = false;
          }
        } else {
          if (isTargetNullable) {
            params.add(
              Parameter((p) {
                p.name = fieldName;
                p.type = referType(fieldType);
                p.named = true;
              }),
            );
            setFieldNames[fieldName] = false;
          } else {
            params.add(
              Parameter((p) {
                p.name = fieldName;
                p.type = referType(fieldType);
                p.required = true;
                p.named = true;
              }),
            );
            setFieldNames[fieldName] = true;
          }
        }
      }

      final body = <String>[];
      body.add('final _patcher = ${targetClassName}Patch();');

      for (final field in targetFieldsDistinct) {
        final fieldName = field.name;
        final fieldNameCap =
            fieldName[0].toUpperCase() + fieldName.substring(1);
        final isRequired = setFieldNames[fieldName] ?? false;

        if (isRequired) {
          body.add('_patcher.with$fieldNameCap($fieldName);');
        } else {
          body.add('if ($fieldName != null) {');
          body.add('  _patcher.with$fieldNameCap($fieldName);');
          body.add('}');
        }
      }

      // Generate switch expression to call correct toJson() for each sealed subtype
      final subtypeCases = <String>[];
      for (final st in explicitSubTypes) {
        final stName = st.interfaceName.replaceAll(r'$', '');
        // Use a named variable (lowercase first char) instead of discard pattern
        final varName = stName[0].toLowerCase() + stName.substring(1);
        subtypeCases.add('$stName $varName => $varName.toJson()');
      }
      // For non-sealed polymorphic bases the base class itself is
      // instantiable, so `switch (this)` over the base type must also cover
      // the base case — otherwise the switch is non-exhaustive ("doesn't
      // match 'X()'"). A wildcard default keeps it exhaustive. `shouldGenerate`
      // has already refused the extension when that default would call a
      // `toJson()` the base never declared, so this is the same predicate the
      // gate reads, not a second guess at it.
      if (baseCase) {
        subtypeCases.add('_ => this.toJson()');
      }
      body.add('final _json = Map<String, dynamic>.from(');
      body.add('  switch (this) {');
      for (final caseStr in subtypeCases) {
        body.add('    $caseStr,');
      }
      body.add('  },');
      body.add(');');
      body.add('_json.addAll(_patcher.toJson());');
      body.add('return $targetClassName.fromJson(_json);');

      methods.add(
        Method((m) {
          m.name = 'changeTo$targetClassName';
          m.returns = referType(targetClassName);
          m.optionalParameters.addAll(params);
          m.body = Code(body.join('\n'));
        }),
      );
    }

    return Extension((e) {
      e.name = '${sourceClassNameTrimmed}ChangeToE';
      e.on = referType(sourceClassNameTrimmed);
      e.methods.addAll(methods);
    });
  }
}
