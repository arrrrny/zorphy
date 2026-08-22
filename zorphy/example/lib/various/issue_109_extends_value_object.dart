// Regression fixture for issue #109 — Dart `extends` on the abstract
// class alongside `implements`/`sealed`.
//
// Before the fix, zorphy rejected any `extends` clause on a `@Zorphy`-
// annotated abstract class with:
//
//   Exception("you must use implements, not extends")
//
// That blocked value-object / entity hierarchies where the abstract
// subclass should *inherit* getters from a base abstract class (not
// merely satisfy its interface). The motivating use case is the
// zikzak_inappwebview v6 auth-challenge family:
//
//   @Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
//   abstract class $UrlAuthenticationChallenge {
//     String get protectionSpace;
//   }
//
//   @Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
//   abstract class $ServerTrustAuthResponse extends $UrlAuthenticationChallenge {
//     String get action;
//   }
//
// Expected generated output:
//
//   class UrlAuthenticationChallenge { ... }
//   class ServerTrustAuthResponse extends UrlAuthenticationChallenge { ... }
//
// With the fix, the supertype flows through `classElement.allSupertypes`
// -> `InterfaceCollector.collect` -> `metadata.interfaces` and is
// routed to `c.extend` by `ClassDeclarationGenerator._getExtendedParentName`,
// producing `class ServerTrustAuthResponse extends UrlAuthenticationChallenge`
// on the generated concrete class — proper Dart inheritance, so
// `isA<UrlAuthenticationChallenge>()` holds at runtime and the
// subclass inherits the base's fields, copyWith, equality, etc.
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_109_extends_value_object.zorphy.dart';
part 'issue_109_extends_value_object.g.dart';

// ── Scenario 1: value-object hierarchy via `extends` ─────────────────
//
// Mirrors the issue's exact use case. `ServerTrustAuthResponse` is a
// value object that extends `UrlAuthenticationChallenge`, inheriting
// `protectionSpace` and adding its own `action`.

@Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
abstract class $UrlAuthenticationChallenge {
  String get protectionSpace;
}

@Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
abstract class $ServerTrustAuthResponse extends $UrlAuthenticationChallenge {
  String get action;
}

// ── Scenario 2: extends + extra fields (constructor shape) ──────────
//
// A deeper subclass that adds its own field — exercises the field
// resolver's "all supertypes" walk and the concrete constructor's
// `super()` call against an abstract base.

@Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
abstract class $ClientCertChallenge extends $UrlAuthenticationChallenge {
  String get certHost;
}

// ── Scenario 3: extends-implements combination ──────────────────────
//
// A class that both `extends` a zorphy base AND `implements` an extra
// interface — the generator must emit
//   `class Foo extends Base implements Extra { ... }`
// so the Base relationship is inheritance (with `super()`) and only the
// Extra is a pure interface.

@Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
abstract class $HttpAuthChallenge extends $UrlAuthenticationChallenge {
  String get scheme;
}
