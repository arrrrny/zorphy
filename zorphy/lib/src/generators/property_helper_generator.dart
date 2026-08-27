import 'package:code_builder/code_builder.dart';

import '../common/NameType.dart';
import 'base_generator.dart';

/// Generates semantic property helpers (hasField, isSubtype, etc.).
///
/// Produces native [Extension] specs for semantic property helpers.
class PropertyHelperGenerator extends UniversalGenerator {
  /// Creates a generator for property helper extensions.
  PropertyHelperGenerator();

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final specs = <Spec>[];

    // 1. Polymorphic helpers extension
    if (metadata.explicitSubtypes.isNotEmpty) {
      specs.add(_buildPolymorphicExtension(metadata));
    }

    // 2. Field-specific helpers extension
    final ownFields = metadata.allFields
        .where((f) => metadata.ownFieldNames.contains(f.name))
        .toList();
    if (ownFields.isNotEmpty) {
      specs.add(_buildPropertyHelpersExtension(metadata, ownFields));
    }

    return specs;
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    if (!context.config.generatePropertyHelpers) return false;
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.polymorphicSubtypes.isNotEmpty;
  }

  // ── Polymorphic extension ───────────────────────────────────────

  Extension _buildPolymorphicExtension(dynamic metadata) {
    final genericNames = metadata.generics.isEmpty
        ? ''
        : '<${metadata.generics.map((g) => g.name).join(', ')}>';
    final genericDefs = metadata.generics.isEmpty
        ? ''
        : '<${metadata.generics.map((g) => g.bound != null ? '${g.name} extends ${g.bound}' : g.name).join(', ')}>';

    final methods = <Method>[];
    for (final subtype in metadata.explicitSubtypes) {
      final subtypeName = subtype.interfaceName.replaceAll(r'$', '');
      if (metadata.cleanName != subtypeName) {
        methods.add(
          Method((m) {
            m.name = 'is$subtypeName';
            m.type = MethodType.getter;
            m.returns = refer('bool');
            m.body = Code('return this is $subtypeName;');
          }),
        );
        methods.add(
          Method((m) {
            m.name = 'as$subtypeName';
            m.type = MethodType.getter;
            m.returns = refer('${subtypeName}?');
            m.body = Code(
              'return this is $subtypeName ? this as $subtypeName : null;',
            );
          }),
        );
      }
    }

    return Extension((e) {
      e.name = '${metadata.cleanName}PolymorphicE$genericDefs';
      e.on = refer('${metadata.cleanName}$genericNames');
      e.methods.addAll(methods);
    });
  }

  // ── Property helpers extension ──────────────────────────────────

  Extension _buildPropertyHelpersExtension(
    dynamic metadata,
    List<NameTypeClassComment> ownFields,
  ) {
    final genericNames = metadata.generics.isEmpty
        ? ''
        : '<${metadata.generics.map((g) => g.name).join(', ')}>';
    final genericDefs = metadata.generics.isEmpty
        ? ''
        : '<${metadata.generics.map((g) => g.bound != null ? '${g.name} extends ${g.bound}' : g.name).join(', ')}>';

    final methods = <Method>[];

    for (final field in ownFields) {
      var type = field.type ?? 'dynamic';
      type = type.replaceAll(r'$', '');

      final fieldName = field.name;
      final isNullable = type.endsWith('?');
      final isCollection =
          type.startsWith('List<') ||
          type.startsWith('Map<') ||
          type.startsWith('Set<');

      final baseName = fieldName.startsWith('_')
          ? fieldName.substring(1)
          : fieldName;
      final capitalized = baseName[0].toUpperCase() + baseName.substring(1);

      final isString = type.replaceAll('?', '') == 'String';

      if (isNullable && !isCollection && !isString) {
        methods.add(
          Method((m) {
            m.name = 'has$capitalized';
            m.type = MethodType.getter;
            m.returns = refer('bool');
            m.body = Code('return this.$fieldName != null;');
          }),
        );
        methods.add(
          Method((m) {
            m.name = 'no$capitalized';
            m.type = MethodType.getter;
            m.returns = refer('bool');
            m.body = Code('return this.$fieldName == null;');
          }),
        );
        final nonNullableType = type.substring(0, type.length - 1);
        methods.add(
          Method((m) {
            m.name = '${baseName}Required';
            m.type = MethodType.getter;
            m.returns = refer(nonNullableType);
            m.body = Code(
              "return this.$fieldName ?? (throw StateError('$fieldName is required but was null'));",
            );
          }),
        );
      } else if (isNullable && isCollection) {
        final nonNullableType = type.substring(0, type.length - 1);
        methods.add(
          Method((m) {
            m.name = '${baseName}Required';
            m.type = MethodType.getter;
            m.returns = refer(nonNullableType);
            m.body = Code(
              "return this.$fieldName ?? (throw StateError('$fieldName is required but was null'));",
            );
          }),
        );
      }

      if (isString) {
        if (isNullable) {
          methods.add(
            Method((m) {
              m.name = 'has$capitalized';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName?.isNotEmpty == true;');
            }),
          );
          methods.add(
            Method((m) {
              m.name = 'no$capitalized';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName?.isEmpty ?? true;');
            }),
          );
          final nonNullableType = type.substring(0, type.length - 1);
          methods.add(
            Method((m) {
              m.name = '${baseName}Required';
              m.type = MethodType.getter;
              m.returns = refer(nonNullableType);
              m.body = Code(
                "return this.$fieldName ?? (throw StateError('$fieldName is required but was null'));",
              );
            }),
          );
        } else {
          methods.add(
            Method((m) {
              m.name = 'has$capitalized';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName.isNotEmpty;');
            }),
          );
          methods.add(
            Method((m) {
              m.name = 'no$capitalized';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName.isEmpty;');
            }),
          );
        }
      }

      if (isCollection) {
        if (!isNullable) {
          methods.add(
            Method((m) {
              m.name = 'has$capitalized';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName.isNotEmpty;');
            }),
          );
          methods.add(
            Method((m) {
              m.name = 'no$capitalized';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName.isEmpty;');
            }),
          );
        } else {
          methods.add(
            Method((m) {
              m.name = 'has$capitalized';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName?.isNotEmpty ?? false;');
            }),
          );
          methods.add(
            Method((m) {
              m.name = 'no$capitalized';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName?.isEmpty ?? true;');
            }),
          );
        }
      }

      if (field.isEnum && field.enumValues.isNotEmpty) {
        final baseEnumName = type.replaceAll('?', '');
        for (final value in field.enumValues) {
          final capitalizedValue = value[0].toUpperCase() + value.substring(1);
          methods.add(
            Method((m) {
              m.name = 'is$capitalized$capitalizedValue';
              m.type = MethodType.getter;
              m.returns = refer('bool');
              m.body = Code('return this.$fieldName == $baseEnumName.$value;');
            }),
          );
        }
      }
    }

    return Extension((e) {
      e.name = '${metadata.cleanName}PropertyHelpers$genericDefs';
      e.on = refer('${metadata.cleanName}$genericNames');
      e.methods.addAll(methods);
    });
  }
}
