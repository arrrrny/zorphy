import 'package:code_builder/code_builder.dart';

import '../common/NameType.dart';
import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates equals, hashCode, and toString methods.
///
/// Migrated (T009): [generateSpec] now produces native [Method] specs
/// instead of delegating to string-based helpers. The legacy [generate]
/// path is preserved for backward compatibility with the string pipeline.
class EqualsToStringGenerator extends ConcreteClassGenerator
    implements SpecGenerator {
  /// Creates a generator for equality and toString members.
  EqualsToStringGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Generate equals and hashCode
    sb.writeln(helpers.getEqualsAndHashCode(metadata.allFields, className));

    // Generate toString
    sb.writeln(helpers.getToString(metadata.allFields, className));

    return sb.toString();
  }

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
    final body = StringBuffer();
    body.writeln('if (identical(this, other)) return true;');

    if (fields.isEmpty) {
      body.writeln('return other is $className;');
    } else {
      body.write('return other is $className');
      for (final f in fields) {
        body.write(' &&\n    ${f.name} == other.${f.name}');
      }
      body.writeln(';');
    }

    return Method((m) {
      m.annotations.add(refer('override'));
      m.name = '==';
      m.returns = refer('bool');
      m.requiredParameters.add(Parameter((p) {
        p.name = 'other';
        p.type = refer('Object');
      }));
      m.body = Code(body.toString());
    });
  }

  // ── hashCode getter ─────────────────────────────────────────────

  Method _buildHashCodeGetter(List<NameTypeClassComment> fields) {
    final body = StringBuffer();

    if (fields.isEmpty) {
      body.writeln('return 0;');
    } else if (fields.length == 1) {
      body.writeln('return Object.hash(${fields[0].name}, 0);');
    } else if (fields.length <= 20) {
      body.writeln('return Object.hash(');
      for (var i = 0; i < fields.length; i++) {
        final comma = i == fields.length - 1 ? ');' : ',';
        body.writeln('  this.${fields[i].name}$comma');
      }
    } else {
      // Chunk into groups of 20
      final chunkSize = 20;
      final chunks = (fields.length / chunkSize).ceil();

      for (var c = 0; c < chunks; c++) {
        final start = c * chunkSize;
        final end = (start + chunkSize).clamp(0, fields.length);
        final chunkFields = fields.sublist(start, end);

        if (c == 0) {
          body.write('return Object.hash(');
          for (var i = 0; i < chunkFields.length; i++) {
            final comma =
                i == chunkFields.length - 1 ? ')' : ',';
            body.write('this.${chunkFields[i].name}$comma');
          }
        } else {
          body.write(' ^ Object.hash(');
          for (var i = 0; i < chunkFields.length; i++) {
            final comma = i == chunkFields.length - 1
                ? (chunkFields.length == 1 ? ', 0)' : ')')
                : ',';
            body.write('this.${chunkFields[i].name}$comma');
          }
        }
      }
      body.writeln(';');
    }

    return Method((m) {
      m.annotations.add(refer('override'));
      m.name = 'hashCode';
      m.type = MethodType.getter;
      m.returns = refer('int');
      m.body = Code(body.toString());
    });
  }

  // ── toString override ───────────────────────────────────────────

  Method _buildToStringMethod(
    List<NameTypeClassComment> fields,
    String className,
  ) {
    final body = StringBuffer();

    if (fields.isEmpty) {
      body.writeln("return '$className()';");
    } else {
      body.writeln("return '$className(' +");
      for (var i = 0; i < fields.length; i++) {
        final f = fields[i];
        final isLast = i == fields.length - 1;
        if (isLast) {
          body.writeln(
            "        '${f.name}: \${${f.name}})';",
          );
        } else {
          body.writeln(
            "        '${f.name}: \${${f.name}}' + ', ' +",
          );
        }
      }
    }

    return Method((m) {
      m.annotations.add(refer('override'));
      m.name = 'toString';
      m.returns = refer('String');
      m.body = Code(body.toString());
    });
  }
}
