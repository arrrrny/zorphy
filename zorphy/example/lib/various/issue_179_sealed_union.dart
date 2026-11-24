import 'package:zorphy_annotation/zorphy_annotation.dart';

part '../_br_/various/issue_179_sealed_union.part.dart';

/// The `@ZorphyUnion` shape from issue #179 §2: a CLOSED hierarchy (a `$$`
/// root), which is what makes the emitted `when` / `maybeWhen` switch
/// exhaustive over the declared variants.
///
/// Exercised at runtime by `example/tool/issue_179_behavior_check.dart`.
@Zorphy(explicitSubTypes: [$OrderNotification179S, $PriceDropNotification179S])
abstract class $$Notification179S {
  String get id;

  DateTime get createdAt;

  DateTime? get readAt;
}

@Zorphy()
abstract class $OrderNotification179S implements $$Notification179S {
  String get orderId;
}

@Zorphy()
abstract class $PriceDropNotification179S implements $$Notification179S {
  String get productId;

  double get oldPrice;

  double get newPrice;
}
