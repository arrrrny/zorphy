import 'package:zorphy_annotation/zorphy_annotation.dart';

part '../_br_/various/issue_179_union_morphing.part.dart';

/// The shape from issue #179 §2: two siblings sharing a `$Parent` root with
/// `id` / `createdAt` / `readAt`. `generateJson` is off, so the sibling
/// morphing method must not round-trip through a JSON surface the hierarchy
/// never asked for.
///
/// Exercised at runtime by `example/tool/issue_179_behavior_check.dart`.
@Zorphy(explicitSubTypes: [$OrderNotification179, $PriceDropNotification179])
abstract class $Notification179 {
  String get id;

  DateTime get createdAt;

  DateTime? get readAt;
}

@Zorphy()
abstract class $OrderNotification179 implements $Notification179 {
  String get orderId;
}

@Zorphy()
abstract class $PriceDropNotification179 implements $Notification179 {
  String get productId;

  double get oldPrice;

  double get newPrice;
}
