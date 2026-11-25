// v2 fixture: a value object with no `id` field and generate* toggles.
import 'package:zorphy_annotation/zorphy_annotation.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $Money {
  final int amount;
  final String currency;

  const $Money({required this.amount, required this.currency});
}