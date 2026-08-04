import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
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

    for (final factory in metadata.factoryMethods) {
      final factoryClass = factory.className;
      final isTrulyRecursive = factoryClass == classNameTrimmed;
      if (isTrulyRecursive) continue;

      final code = helpers.generateFactoryMethod(
        factory,
        classNameTrimmed,
        metadata.allFields,
      );

      // The helper produces something like:
      //   factory ClassName.methodName(params) => bodyCode;
      // We need to extract: name, params, body, and whether it's a lambda.
      final spec = _parseFactoryString(code, classNameTrimmed);
      if (spec != null) {
        return [ClassMemberCode.constructor(spec)];
      }
    }

    return [];
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    final metadata = context.metadata;
    final className = metadata.cleanName;

    if (metadata.isAbstract) return false;

    return metadata.factoryMethods.any((f) {
      var factoryClass = f.className;
      var isTrulyRecursive = factoryClass == className;
      return !isTrulyRecursive;
    });
  }

  /// Parses a factory method string into a [Constructor] spec.
  ///
  /// Expects format: `factory ClassName.name(...) => expr;` or
  /// `factory ClassName.name(...) { ... }`
  static Constructor? _parseFactoryString(
      String code, String className) {
    // Strip leading whitespace
    final trimmed = code.trim();
    if (!trimmed.startsWith('factory ')) return null;

    // Find the opening paren
    final parenIndex = trimmed.indexOf('(');
    if (parenIndex == -1) return null;

    // Extract name (between 'factory ' and '(')
    final namePart = trimmed.substring(7, parenIndex).trim();
    // namePart is like 'ClassName.methodName' — we just need the method name
    final dotIndex = namePart.indexOf('.');
    final name = dotIndex != -1
        ? namePart.substring(dotIndex + 1)
        : namePart;

    // Find matching closing paren
    var depth = 0;
    var closeParenIndex = -1;
    for (var i = parenIndex; i < trimmed.length; i++) {
      if (trimmed[i] == '(') {
        depth++;
      } else if (trimmed[i] == ')') {
        depth--;
        if (depth == 0) {
          closeParenIndex = i;
          break;
        }
      }
    }
    if (closeParenIndex == -1) return null;

    // Check if it's a lambda (=>) or block body ({})
    final afterParen = trimmed.substring(closeParenIndex + 1).trim();
    final isLambda = afterParen.startsWith('=>');

    if (isLambda) {
      // => expression;
      final bodyCode = afterParen.substring(2).trim();
      if (bodyCode.endsWith(';')) {
        final inner = bodyCode.substring(0, bodyCode.length - 1).trim();
        return Constructor((c) {
          c.factory = true;
          c.name = name;
          c.lambda = true;
          c.body = Code(inner);
        });
      }
    } else {
      // Block body: { ... }
      if (afterParen.startsWith('{')) {
        // Find matching close brace
        depth = 0;
        var closeBraceIndex = -1;
        for (var i = closeParenIndex + 1; i < trimmed.length; i++) {
          if (trimmed[i] == '{') {
            depth++;
          } else if (trimmed[i] == '}') {
            depth--;
            if (depth == 0) {
              closeBraceIndex = i;
              break;
            }
          }
        }
        if (closeBraceIndex == -1) return null;
        final inner = trimmed
            .substring(closeParenIndex + 2, closeBraceIndex)
            .trimRight();
        return Constructor((c) {
          c.factory = true;
          c.name = name;
          c.body = Code(inner);
        });
      }
    }

    return null;
  }
}
