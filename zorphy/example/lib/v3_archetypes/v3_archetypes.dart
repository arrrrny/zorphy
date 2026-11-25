import 'package:zorphy_annotation/zorphy_annotation.dart';

part '../_br_/v3_archetypes/v3_archetypes.part.dart';

// Issue #223 e2e fixture: one class per v3 archetype, declared the way a real
// consumer declares them (abstract `$`-prefixed declarations; the generated
// classes drop the prefix). The production builder must turn every one of
// these into its archetype's surface in the shared part.

// ── @ZorphyEntity — an aggregate root with identity + one leaf ──────────────
@ZorphyEntity(principalKey: #id)
abstract class $Notification {
  String get id;
  String get title;
}

@ZorphyEntity()
abstract class $OrderNotification implements $Notification {
  String get orderId;
}

// ── @ZorphyEntity — standalone, no hierarchy ────────────────────────────────
@ZorphyEntity(principalKey: #id)
abstract class $Product {
  String get id;
  String get name;
}

// ── @ZorphyEntity — three levels: root → abstract intermediate → leaf ───────
@ZorphyEntity(principalKey: #id)
abstract class $Event {
  String get id;
}

@ZorphyEntity()
abstract class $SystemEvent implements $Event {
  String get source;
}

@ZorphyEntity()
abstract class $DeployEvent implements $SystemEvent {
  String get version;
}

// ── @ZorphyState — a sealed state hierarchy ─────────────────────────────────
@ZorphyState()
abstract class $UiState {
  String get label;
}

@ZorphyState()
abstract class $ReadyState implements $UiState {
  String get detail;
}

// ── @ZorphyUnion — a closed union with factory variants ─────────────────────
// Union variants must be CONCRETE and implement the union root: a redirecting
// factory cannot target an abstract class, and its target must be a subtype
// of the union.
@ZorphyUnion()
abstract class $AsyncStatus {
  factory $AsyncStatus.loading() = $Loading;
  factory $AsyncStatus.ready(String value) = $Ready;
}

@ZorphyValue()
class $Loading implements $AsyncStatus {
  const $Loading();
}

@ZorphyValue()
class $Ready implements $AsyncStatus {
  final String value;

  const $Ready(this.value);
}

// ── @ZorphyIntent — a replay-safe command envelope ──────────────────────────
@ZorphyIntent(replaySafe: true)
abstract class $InspectProductIntent {
  String get productId;
}

// ── @ZorphyIntent — a polymorphic hierarchy (#232) ──────────────────────────
// The issue's acceptance gate needs real build_runner output for the
// discriminator dispatch: a sealed intent root, two leaves with their own
// replaySafe decisions, and the MockData rotation across them.
@ZorphyIntent(replaySafe: false)
abstract class $CartIntent {
  String get cartId;
}

@ZorphyIntent(replaySafe: true)
abstract class $AddToCartIntent implements $CartIntent {
  String get sku;
}

@ZorphyIntent(replaySafe: false)
abstract class $RemoveFromCartIntent implements $CartIntent {
  String get reason;
}

// ── @ZorphyEntity — carries an intent-valued field (#232) ───────────────────
// The entity codec must decode `pending` through `$CartIntent`'s own
// `fromWire` instead of treating it as an unvalidated raw wire value.
@ZorphyEntity(principalKey: #id)
abstract class $CheckoutSession {
  String get id;
  $CartIntent? get pending;
}

// ── @ZorphyValue — an immutable value object, no identity ───────────────────
// The issue's own reproduction shape.
@ZorphyValue()
abstract class $Greeting {
  String get message;
}

// ── @ZorphyValue — a nested value the pointer resolver descends into ─────────
@ZorphyValue()
abstract class $EditDraft {
  String get title;
  double get price;
}

// ── @ZorphyState — a state carrying a nested value (/editDraft/price) ────────
@ZorphyState()
abstract class $ProductUiState {
  $EditDraft get editDraft;
  int get selectedTab;
}

// ── @ZorphyState — a three-level hierarchy with a SIBLING leaf ───────────────
// `mode` is subtype-only (the interactive branch), `label` belongs to the button
// and `text` to the text node, so resolving a segment a receiver does not carry
// answers null instead of throwing — the safe-dispatch acceptance case.
@ZorphyState()
abstract class $UiNode {
  String get contractId;
}

@ZorphyState()
abstract class $InteractiveUiNode implements $UiNode {
  String get mode;
}

@ZorphyState()
abstract class $ZfaButtonNode implements $InteractiveUiNode {
  String get label;
}

@ZorphyState()
abstract class $ZfaTextNode implements $UiNode {
  String get text;
}
