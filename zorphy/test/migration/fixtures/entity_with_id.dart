// v2 fixture: an entity root with an `id` field and v2 preset/generate* args.
import 'package:zorphy_annotation/zorphy_annotation.dart';

@Zorphy(preset: ZorphyPreset.full, generateJson: true, generatePatch: false)
abstract class $User {
  final String id;
  final String name;

  const $User({required this.id, required this.name});
}