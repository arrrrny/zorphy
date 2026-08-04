import 'package:code_builder/code_builder.dart';

import '../common/NameType.dart';
import 'base_generator.dart';

/// Generates equals, hashCode, and toString methods.
///
/// Produces native [Method] specs.
class EqualsToStringGenerator extends ConcreteClassGenerator {
  /// Creates a generator for equality and toString members.
  EqualsToStringGenerator();

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final fields = metadata.allFields;
    final className = metadata.cleanName;

    return [
      _buildEqualsOperator(fields, className),
      _buildHashCodeGetter(fields),
      _buildToStringMethod(fields, className),
    ];
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return !context.metadata.isAbstract &&
        context.config.generateEqualsToString;
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
      m.requiredParameters.add(Parameter((p) {
        p.name = 'other';
        p.type = refer('Object');
      }));
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
      final fieldRefs = fields
          .map((f) => 'this.${f.name}')
          .join(', ');
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
        final fieldRefs = chunkFields
            .map((f) => 'this.${f.name}')
            .join(', ');

        if (c == 0) {
          parts.add('Object.hash($fieldRefs)');
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
