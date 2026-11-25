// v2 fixture: a sealed polymorphic hierarchy and codec call sites.
import 'package:zorphy_annotation/zorphy_annotation.dart';

@ZorphySealed()
abstract class $Shape {
  const $Shape();
}

@Zorphy(preset: ZorphyPreset.lean)
abstract class $Circle implements $Shape {
  final String id;
  final double radius;

  const $Circle({required this.id, required this.radius});
}

User decodeUser(Map<String, Object?> map) => User.fromJson(map);

Map<String, Object?> encodeUser(User user) => user.toJson();
