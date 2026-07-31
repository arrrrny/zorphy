import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'vs_freezed_nested_patch.zorphy.dart';

/// Example 3 — nested partial updates: zorphy's patch system.
///
/// In freezed, updating one nested field requires manual deep copyWith
/// chains:
/// ```dart
/// user.copyWith(address: user.address.copyWith(city: 'Berlin'));
/// ```
///
/// Zorphy generates composable patch classes instead — see [main].
@Zorphy(generatePatch: true)
abstract class $Address {
  String get street;
  String get city;
}

@Zorphy(generatePatch: true)
abstract class $Profile {
  String get name;
  $Address get address;
}

/// Applies a nested patch: rename the profile and change only the city.
Profile updateProfile(Profile profile) {
  final patch = ProfilePatch()
    ..withName('Ada')
    ..withAddressPatch(AddressPatch()..withCity('Berlin'));
  return patch.applyTo(profile);
}
