import 'package:code_builder/code_builder.dart';

import '../common/NameType.dart';
import 'base_generator.dart';

/// Generates equals, hashCode, and toString methods.
///
/// Produces native [Method] specs.
///
/// Honors `GenerationConfig.equalityExcludes` (issue #127): fields whose
/// Dart name is listed in `equalityExcludes` are dropped from `operator
/// ==` and `hashCode`. `toString()` is NEVER filtered — debug output
/// keeps every field for diagnostics. `equalityExcludes` does not affect
/// `toString()` because debug output is not a comparison surface.
class EqualsToStringGenerator extends ConcreteClassGenerator {
  /// Creates a generator for equality and toString members.
  EqualsToStringGenerator();

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final allFields = metadata.allFields;
    final className = metadata.cleanName;
    // Fields used by == / hashCode drop the excluded names; toString
    // keeps every field so debug output is unchanged.
    final equalityFields = _filterExcluded(allFields, context);

    return [
      _buildEqualsOperator(equalityFields, className),
      _buildHashCodeGetter(equalityFields),
      _buildToStringMethod(allFields, className),
    ];
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return !context.metadata.isAbstract &&
        context.config.generateEqualsToString;
  }

  /// Returns the subset of [fields] whose Dart name is NOT in
  /// `config.equalityExcludes`. The comparison is case-sensitive and
  /// matches the field's Dart name (NOT a `@JsonKey(name: ...)` alias).
  static List<NameTypeClassComment> _filterExcluded(
    List<NameTypeClassComment> fields,
    GenerationContext context,
  ) {
    final excludes = context.config.equalityExcludes;
    if (excludes.isEmpty) return fields;
    final set = excludes.toSet();
    return fields.where((f) => !set.contains(f.name)).toList();
  }

  // ── equals operator ─────────────────────────────────────────────

  Method _buildEqualsOperator(
    List<NameTypeClassComment> fields,
    String className,
  ) {
    final body = <String>[];
    body.add('if (identical(this, other)) return true;');

    if (fields.isEmpty) {
      body.add('return other is $className;');
    } else {
      final fieldChecks = fields
          .map((f) => '${f.name} == other.${f.name}')
          .join(' &&\n    ');
      body.add('return other is $className &&\n    $fieldChecks;');
    }

    return Method((m) {
      m.annotations.add(refer('override'));
      m.name = 'operator ==';
      m.returns = refer('bool');
      m.requiredParameters.add(
        Parameter((p) {
          p.name = 'other';
          p.type = refer('Object');
        }),
      );
      m.body = Code(body.join('\n'));
    });
  }

  // ── hashCode getter ─────────────────────────────────────────────

  Method _buildHashCodeGetter(List<NameTypeClassComment> fields) {
    final body = <String>[];

    if (fields.isEmpty) {
      body.add('return 0;');
    } else if (fields.length == 1) {
      body.add('return Object.hash(${fields[0].name}, 0);');
    } else if (fields.length <= 20) {
      final fieldRefs = fields.map((f) => 'this.${f.name}').join(', ');
      body.add('return Object.hash($fieldRefs);');
    } else {
      // Chunk into groups of 20
      final chunkSize = 20;
      final chunks = (fields.length / chunkSize).ceil();
      final parts = <String>[];

      for (var c = 0; c < chunks; c++) {
        final start = c * chunkSize;
        final end = (start + chunkSize).clamp(0, fields.length);
        final chunkFields = fields.sublist(start, end);
        final fieldRefs = chunkFields.map((f) => 'this.${f.name}').join(', ');

        if (chunkFields.length == 1) {
          parts.add('Object.hash($fieldRefs, 0)');
        } else {
          parts.add('Object.hash($fieldRefs)');
        }
      }
      body.add('return ${parts.join(' ^ ')};');
    }

    return Method((m) {
      m.annotations.add(refer('override'));
      m.name = 'hashCode';
      m.type = MethodType.getter;
      m.returns = refer('int');
      m.body = Code(body.join('\n'));
    });
  }

  // ── toString override ───────────────────────────────────────────

  Method _buildToStringMethod(
    List<NameTypeClassComment> fields,
    String className,
  ) {
    final body = <String>[];

    if (fields.isEmpty) {
      body.add("return '$className()';");
    } else {
      final parts = <String>[];
      for (var i = 0; i < fields.length; i++) {
        final f = fields[i];
        final isLast = i == fields.length - 1;
        if (isLast) {
          parts.add("'${f.name}: \${${f.name}})';");
        } else {
          parts.add("'${f.name}: \${${f.name}}' + ', ' +");
        }
      }
      body.add("return '$className(' +");
      for (final part in parts) {
        body.add('        $part');
      }
    }

    return Method((m) {
      m.annotations.add(refer('override'));
      m.name = 'toString';
      m.returns = refer('String');
      m.body = Code(body.join('\n'));
    });
  }
}
