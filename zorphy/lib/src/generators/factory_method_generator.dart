import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import '../factory_method.dart';
import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates factory method constructors as [ClassMemberCode.constructor].
///
/// Factory constructors are represented as [Constructor] specs which
/// do not implement [Spec], so we wrap them in [ClassMemberCode]
/// for the orchestrator to inject into the class.
class FactoryMethodGenerator extends ConcreteClassGenerator {
  /// Creates a generator for factory constructors.
  FactoryMethodGenerator();

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final classNameTrimmed = metadata.cleanName;
    final result = <Spec>[];

    for (final factory in metadata.factoryMethods) {
      final factoryClass = factory.className;
      final isTrulyRecursive = factoryClass == classNameTrimmed;
      if (isTrulyRecursive) continue;

      // Skip factories whose parameter types could not be resolved
      // (e.g. a static factory whose parameter is another generated
      // entity). Emitting `InvalidType` would produce uncompilable code,
      // and these factories were never generated before the source-
      // recovery path existed, so skipping preserves prior behavior.
      if (factory.parameters.any((p) => p.type.contains('InvalidType'))) {
        continue;
      }

      final spec = _buildFactoryConstructor(factory, classNameTrimmed);
      if (spec != null) {
        result.add(ClassMemberCode.constructor(spec));
      }
    }

    return result;
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    final metadata = context.metadata;
    final className = metadata.cleanName;

    if (metadata.isAbstract) return false;

    return metadata.factoryMethods.any((f) {
      final isTrulyRecursive = f.className == className;
      if (isTrulyRecursive) return false;
      if (f.parameters.any((p) => p.type.contains('InvalidType'))) {
        return false;
      }
      return true;
    });
  }

  /// Builds a [Constructor] directly from structured [FactoryMethodInfo],
  /// avoiding a string round-trip that previously dropped parameters.
  static Constructor? _buildFactoryConstructor(
    FactoryMethodInfo factory,
    String classNameTrimmed,
  ) {
    // Determine body
    final useAbstractFactoryCall = factory.bodyCode.trim().isEmpty;
    String bodyCode;

    if (useAbstractFactoryCall) {
      // Static method delegated to abstract class
      final callArgs = factory.parameters
          .map((p) => p.isNamed ? '${p.name}: ${p.name}' : p.name)
          .join(', ');
      bodyCode = '${factory.className}.${factory.name}($callArgs)';
    } else {
      bodyCode = factory.bodyCode;
    }

    // Process bodyCode (mirrors helpers.generateFactoryMethod logic)
    final trimmedBody = bodyCode.trim();
    if (trimmedBody.startsWith('return ') && trimmedBody.endsWith(';')) {
      bodyCode = trimmedBody.substring(7, trimmedBody.length - 1);
    }

    if (!useAbstractFactoryCall) {
      // Strip $ prefix from class references in real factory bodies
      final plainClassName = factory.className.replaceAll('\$', '');
      bodyCode = bodyCode
          .replaceAll('${factory.className}._', '${classNameTrimmed}._')
          .replaceAll('${plainClassName}._', '${classNameTrimmed}._');
    }

    // Build parameters from structured data
    final requiredParams = <Parameter>[];
    final namedParams = <Parameter>[];

    for (final p in factory.parameters) {
      final cleanType = helpers.replaceDollarTypesWithConcrete(p.type);
      final param = Parameter((param) {
        param.name = p.name;
        param.type = referType(cleanType);
        if (p.isNamed) {
          param.named = true;
          param.required = p.isRequired;
        }
        if (p.hasDefaultValue && p.defaultValue != null) {
          param.defaultTo = Code(p.defaultValue!);
        }
      });

      if (p.isNamed) {
        namedParams.add(param);
      } else {
        requiredParams.add(param);
      }
    }

    return Constructor((c) {
      c.factory = true;
      c.name = factory.name;
      c.lambda = true;
      c.body = Code(bodyCode);
      c.requiredParameters.addAll(requiredParams);
      c.optionalParameters.addAll(namedParams);
    });
  }
}
