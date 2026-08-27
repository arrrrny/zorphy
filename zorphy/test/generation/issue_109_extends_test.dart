import 'dart:io';

import 'package:test/test.dart';

/// Regression tests for issue #109 — Dart `extends` on the abstract
/// class alongside `implements`/`sealed`.
///
/// Before the fix, zorphy rejected any `extends` clause on a
/// `@Zorphy`-annotated abstract class with:
///
///   Exception("you must use implements, not extends")
///
/// That blocked value-object / entity hierarchies where the abstract
/// subclass should *inherit* getters from a base abstract class (not
/// merely satisfy its interface). The motivating use case is the
/// zikzak_inappwebview v6 auth-challenge family:
///
///   @Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
///   abstract class $UrlAuthenticationChallenge { String get protectionSpace; }
///
///   @Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
///   abstract class $ServerTrustAuthResponse extends $UrlAuthenticationChallenge {
///     String get action;
///   }
///
/// Expected generated output:
///
///   class UrlAuthenticationChallenge { ... }
///   class ServerTrustAuthResponse extends UrlAuthenticationChallenge { ... }
///
/// The fix removes the `extends`-rejection guard in
/// `ClassAnalyzer._validateClassStructure` and `ZorphyGenerator._generateForClass`.
/// The supertype flows through the existing `classElement.allSupertypes` ->
/// `InterfaceCollector.collect` -> `metadata.interfaces` pipeline and is
/// routed to `c.extend` by `ClassDeclarationGenerator._getExtendedParentName`
/// — producing proper Dart inheritance on the generated concrete class.
void main() {
  final fixture = File(
    'example/lib/various/issue_109_extends_value_object.zorphy.dart',
  );
  late String output;

  setUpAll(() {
    if (!fixture.existsSync()) {
      fail(
        'Fixture not generated. Run: cd example && '
        'dart run build_runner build --delete-conflicting-outputs',
      );
    }
    output = fixture.readAsStringSync();
  });

  group('#109 — value-object inheritance via Dart `extends`', () {
    test('base value object is generated as a standalone concrete class', () {
      expect(
        output,
        contains('class UrlAuthenticationChallenge {'),
        reason:
            'The base value object has no `extends`, so the generated '
            'concrete class should also have no `extends` clause.',
      );
    });

    test('subclass uses `extends` (not `implements`) on the generated '
        'concrete class', () {
      expect(
        output,
        contains(
          'class ServerTrustAuthResponse extends UrlAuthenticationChallenge',
        ),
        reason:
            'When the abstract class declares `extends \$Base`, the '
            'generated concrete class must emit `class Sub extends Base` — '
            'proper Dart inheritance. Using `implements` would require '
            're-implementing all of Base\'s generated methods '
            '(copyWithBase, patchWithBase, ==, hashCode, toString, ...).',
      );

      expect(
        output,
        isNot(contains('class ServerTrustAuthResponse implements')),
        reason:
            'implements is the wrong relationship for subclassing a '
            'concrete base — it would fail to compile '
            '(non_abstract_class_inherits_abstract_member).',
      );
    });

    test('subclass constructor calls `super()` with the inherited fields', () {
      expect(
        output,
        contains(
          'ServerTrustAuthResponse({\n'
          '    required String protectionSpace,\n'
          '    required String this.action,\n'
          '  }) : super(protectionSpace: protectionSpace);',
        ),
        reason:
            'The subclass constructor must accept the inherited '
            'field `protectionSpace` as a parameter (NOT `this.protectionSpace` '
            'because it isn\'t redeclared on the subclass) and forward it '
            'to the base constructor via `super(protectionSpace: protectionSpace)`. '
            'Only the subclass\'s own field `action` becomes `this.action`.',
      );
    });

    test('inherited field is NOT redeclared on the subclass', () {
      // The subclass should not redeclare `protectionSpace` as a final
      // field — it inherits it via `extends`. Only `action` (the
      // subclass's own field) should appear as a `final String action`.
      final classBlock = _extractClassBlock(output, 'ServerTrustAuthResponse');
      expect(
        classBlock,
        isNotNull,
        reason: 'ServerTrustAuthResponse class block should exist',
      );

      // `final String action;` is the subclass's own field.
      expect(
        classBlock!,
        contains('final String action;'),
        reason:
            'The subclass\'s own field `action` must be declared as '
            '`final String action;` on the generated concrete subclass.',
      );

      // `final String protectionSpace;` MUST NOT appear — that field
      // is inherited from UrlAuthenticationChallenge via `extends`.
      expect(
        classBlock,
        isNot(contains('final String protectionSpace;')),
        reason:
            'Inherited field `protectionSpace` must not be redeclared '
            'on the subclass. It is inherited from the base via `extends`.',
      );
    });

    test(
      'multiple subclasses of the same base are all generated with `extends`',
      () {
        expect(
          output,
          contains(
            'class ClientCertChallenge extends UrlAuthenticationChallenge',
          ),
        );
        expect(
          output,
          contains(
            'class HttpAuthChallenge extends UrlAuthenticationChallenge',
          ),
        );
      },
    );

    test('`isA<Base>()` holds at runtime via inheritance', () {
      // We can't actually execute the example here (it's a part file),
      // but we CAN assert the structural property that makes `isA<Base>()`
      // hold: the generated concrete subclass literally `extends` the
      // generated concrete base.
      expect(
        output,
        contains(
          'class ServerTrustAuthResponse extends UrlAuthenticationChallenge',
        ),
        reason:
            'Without `extends`, `isA<UrlAuthenticationChallenge>()` would '
            'be false at runtime — defeating the purpose of the hierarchy.',
      );
    });
  });
}

/// Extracts the body of the generated class `name` from `output`.
/// Returns the substring from the `class name` declaration up to the
/// matching closing brace at depth 0. Returns null if not found.
String? _extractClassBlock(String output, String name) {
  final pattern = RegExp('class $name\\b');
  final startMatch = pattern.firstMatch(output);
  if (startMatch == null) return null;
  var i = startMatch.end;
  var depth = 0;
  var seenOpen = false;
  while (i < output.length) {
    final ch = output[i];
    if (ch == '{') {
      depth++;
      seenOpen = true;
    } else if (ch == '}') {
      depth--;
      if (seenOpen && depth == 0) {
        return output.substring(startMatch.start, i + 1);
      }
    }
    i++;
  }
  return null;
}
