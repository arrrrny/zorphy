// Runtime fixture for ISSUE-008 (zorphy#183) — nested sub-patches and
// collection deltas.
//
// `Address` and `Profile` stand in for what the generator emits for a pair of
// concrete `@ZorphyEntity` classes: each entity mirror plus its field enum, and
// a patch carrying the full algebra next to the legacy fluent builders.
//
// Both PATCH sections between the markers are byte-identical to `PatchEmitter`'s
// output for these entities — `test/golden/nested_and_collection_patch_golden_test.dart`
// compares them, so a change to the emitter fails that test until the fixture
// (and therefore this real, exercised patch) is regenerated deliberately.
//
// `Profile` carries one field per shape the issue names: a nested Zorphy
// entity (`address`), a nullable nested one (`previousAddress`), a
// `List<String>` (`tags`), a `Map<String, int>` (`scores`) and scalars.

import 'package:zorphy_annotation/zorphy.dart';

/// The `Address` entity's field enum, as `FieldEnumGenerator` emits it.
enum Address$ { street, city, postalCode }

class Address {
  const Address({required this.street, required this.city, this.postalCode});

  final String street;
  final String city;
  final String? postalCode;

  Address copyWith({String? street, String? city, String? postalCode}) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  Address patchWithAddress(AddressPatch? patchInput) {
    final _patcher = patchInput ?? AddressPatch();
    final _patchMap = _patcher.patchMap;
    return Address(
      street: _patchMap.containsKey(Address$.street)
          ? _patchMap[Address$.street] as String
          : this.street,
      city: _patchMap.containsKey(Address$.city)
          ? _patchMap[Address$.city] as String
          : this.city,
      postalCode: _patchMap.containsKey(Address$.postalCode)
          ? _patchMap[Address$.postalCode] as String?
          : this.postalCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          street == other.street &&
          city == other.city &&
          postalCode == other.postalCode;

  @override
  int get hashCode => Object.hash(street, city, postalCode);

  @override
  String toString() =>
      'Address(street: $street, city: $city, postalCode: $postalCode)';
}

// GOLDEN-ADDRESS-PATCH-START
class AddressPatch extends PatchBase<Address, Address$> {
  const AddressPatch.empty() : super.empty();

  AddressPatch() : super();

  /// The canonical empty patch: no change, allocations.
  static const AddressPatch emptyPatch = AddressPatch.empty();

  bool get isEmpty {
    return patchMap.isEmpty;
  }

  Address apply(Address target) {
    if (isEmpty) return target;
    return target.patchWithAddress(this);
  }

  Address applyTo(Address entity) {
    return apply(entity);
  }

  AddressPatch compose(covariant AddressPatch next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    return AddressPatch()
      ..patchMap.addAll(patchMap)
      ..patchMap.addAll(next.patchMap);
  }

  AddressPatch invert(Address before) {
    final undo = AddressPatch();
    if (patchMap.containsKey(Address$.street))
      undo.patchMap[Address$.street] = before.street;
    if (patchMap.containsKey(Address$.city))
      undo.patchMap[Address$.city] = before.city;
    if (patchMap.containsKey(Address$.postalCode))
      undo.patchMap[Address$.postalCode] = before.postalCode;
    return undo;
  }

  static AddressPatch diff(Address previous, Address next) {
    if (identical(previous, next)) return const AddressPatch.empty();
    final changes = AddressPatch();
    if (previous.street != next.street)
      changes.patchMap[Address$.street] = next.street;
    if (previous.city != next.city) changes.patchMap[Address$.city] = next.city;
    if (previous.postalCode != next.postalCode)
      changes.patchMap[Address$.postalCode] = next.postalCode;
    return changes;
  }

  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (patchMap.containsKey(Address$.street))
      wire['street'] = patchMap[Address$.street];
    if (patchMap.containsKey(Address$.city))
      wire['city'] = patchMap[Address$.city];
    if (patchMap.containsKey(Address$.postalCode))
      wire['postalCode'] = patchMap[Address$.postalCode];
    return wire;
  }

  AddressPatch withStreet(String? value) {
    patchMap[Address$.street] = value;
    return this;
  }

  AddressPatch withCity(String? value) {
    patchMap[Address$.city] = value;
    return this;
  }

  AddressPatch withPostalCode(String? value) {
    patchMap[Address$.postalCode] = value;
    return this;
  }
}
// GOLDEN-ADDRESS-PATCH-END

/// The `Profile` entity's field enum.
enum Profile$ { id, displayName, address, tags, scores, previousAddress }

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.address,
    required this.tags,
    required this.scores,
    this.previousAddress,
  });

  final String id;
  final String displayName;
  final Address address;
  final List<String> tags;
  final Map<String, int> scores;
  final Address? previousAddress;

  Profile copyWith({
    String? id,
    String? displayName,
    Address? address,
    List<String>? tags,
    Map<String, int>? scores,
    Address? previousAddress,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      address: address ?? this.address,
      tags: tags ?? this.tags,
      scores: scores ?? this.scores,
      previousAddress: previousAddress ?? this.previousAddress,
    );
  }

  Profile patchWithProfile(ProfilePatch? patchInput) {
    final _patcher = patchInput ?? ProfilePatch();
    final _patchMap = _patcher.patchMap;
    return Profile(
      id: _patchMap.containsKey(Profile$.id)
          ? (((_patchMap[Profile$.id] is Function)
                    ? _patchMap[Profile$.id](this.id)
                    : (_patchMap[Profile$.id] is Patch)
                    ? _patchMap[Profile$.id].applyTo(this.id)
                    : _patchMap[Profile$.id])
                as String)
          : this.id,
      displayName: _patchMap.containsKey(Profile$.displayName)
          ? (((_patchMap[Profile$.displayName] is Function)
                    ? _patchMap[Profile$.displayName](this.displayName)
                    : (_patchMap[Profile$.displayName] is Patch)
                    ? _patchMap[Profile$.displayName].applyTo(this.displayName)
                    : _patchMap[Profile$.displayName])
                as String)
          : this.displayName,
      address: _patchMap.containsKey(Profile$.address)
          ? (((_patchMap[Profile$.address] is Function)
                    ? _patchMap[Profile$.address](this.address)
                    : (_patchMap[Profile$.address] is Patch)
                    ? _patchMap[Profile$.address].applyTo(this.address)
                    : _patchMap[Profile$.address])
                as Address)
          : this.address,
      tags: _patchMap.containsKey(Profile$.tags)
          ? (((_patchMap[Profile$.tags] is Function)
                    ? _patchMap[Profile$.tags](this.tags)
                    : (_patchMap[Profile$.tags] is Patch)
                    ? _patchMap[Profile$.tags].applyTo(this.tags)
                    : _patchMap[Profile$.tags])
                as List<String>)
          : this.tags,
      scores: _patchMap.containsKey(Profile$.scores)
          ? (((_patchMap[Profile$.scores] is Function)
                    ? _patchMap[Profile$.scores](this.scores)
                    : (_patchMap[Profile$.scores] is Patch)
                    ? _patchMap[Profile$.scores].applyTo(this.scores)
                    : _patchMap[Profile$.scores])
                as Map<String, int>)
          : this.scores,
      previousAddress: _patchMap.containsKey(Profile$.previousAddress)
          ? (((_patchMap[Profile$.previousAddress] is Function)
                    ? _patchMap[Profile$.previousAddress](this.previousAddress)
                    : (_patchMap[Profile$.previousAddress] is Patch)
                    ? _patchMap[Profile$.previousAddress].applyTo(
                        this.previousAddress,
                      )
                    : _patchMap[Profile$.previousAddress])
                as Address?)
          : this.previousAddress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          address == other.address &&
          _listEquals(tags, other.tags) &&
          _mapEquals(scores, other.scores) &&
          previousAddress == other.previousAddress;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    address,
    Object.hashAll(tags),
    Object.hashAll(scores.entries.map((e) => Object.hash(e.key, e.value))),
    previousAddress,
  );

  @override
  String toString() =>
      'Profile(id: $id, displayName: $displayName, address: $address, '
      'tags: $tags, scores: $scores, previousAddress: $previousAddress)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

// GOLDEN-PROFILE-PATCH-START
class ProfilePatch extends PatchBase<Profile, Profile$> {
  const ProfilePatch.empty() : super.empty();

  ProfilePatch() : super();

  /// The canonical empty patch: no change, allocations.
  static const ProfilePatch emptyPatch = ProfilePatch.empty();

  bool get isEmpty {
    return patchMap.isEmpty;
  }

  Profile apply(Profile target) {
    if (isEmpty) return target;
    return target.patchWithProfile(this);
  }

  Profile applyTo(Profile entity) {
    return apply(entity);
  }

  ProfilePatch compose(covariant ProfilePatch next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    return ProfilePatch()
      ..patchMap.addAll(patchMap)
      ..patchMap.addAll(next.patchMap);
  }

  ProfilePatch invert(Profile before) {
    final undo = ProfilePatch();
    if (patchMap.containsKey(Profile$.id))
      undo.patchMap[Profile$.id] = before.id;
    if (patchMap.containsKey(Profile$.displayName))
      undo.patchMap[Profile$.displayName] = before.displayName;
    final addressCarried = patchMap[Profile$.address];
    if (patchMap.containsKey(Profile$.address) &&
        addressCarried is PatchNested) {
      undo.patchMap[Profile$.address] =
          (addressCarried as PatchNested<Address, AddressPatch>).invertNested(
            before.address,
          );
    }
    if (patchMap[Profile$.tags] is ListPatchDelta<String>)
      undo.patchMap[Profile$.tags] =
          (patchMap[Profile$.tags] as ListPatchDelta<String>).invert(
            before.tags,
          );
    if (patchMap.containsKey(Profile$.tags) &&
        patchMap[Profile$.tags] is! ListPatchDelta<String>)
      undo.patchMap[Profile$.tags] = before.tags;
    if (patchMap[Profile$.scores] is MapPatchDelta<String, int>)
      undo.patchMap[Profile$.scores] =
          (patchMap[Profile$.scores] as MapPatchDelta<String, int>).invert(
            before.scores,
          );
    if (patchMap.containsKey(Profile$.scores) &&
        patchMap[Profile$.scores] is! MapPatchDelta<String, int>)
      undo.patchMap[Profile$.scores] = before.scores;
    final previousAddressCarried = patchMap[Profile$.previousAddress];
    final previousAddressBefore = before.previousAddress;
    if (patchMap.containsKey(Profile$.previousAddress) &&
        previousAddressCarried is PatchNested &&
        previousAddressBefore != null) {
      undo.patchMap[Profile$.previousAddress] =
          (previousAddressCarried as PatchNested<Address, AddressPatch>)
              .invertNested(previousAddressBefore);
    }
    if (patchMap.containsKey(Profile$.previousAddress) &&
        previousAddressCarried is! PatchNested)
      undo.patchMap[Profile$.previousAddress] = before.previousAddress;
    return undo;
  }

  static ProfilePatch diff(Profile previous, Profile next) {
    if (identical(previous, next)) return const ProfilePatch.empty();
    final changes = ProfilePatch();
    if (previous.id != next.id) changes.patchMap[Profile$.id] = next.id;
    if (previous.displayName != next.displayName)
      changes.patchMap[Profile$.displayName] = next.displayName;
    final addressDelta = AddressPatch.diff(previous.address, next.address);
    if (addressDelta.isNotEmpty)
      changes.patchMap[Profile$.address] = PatchNested<Address, AddressPatch>(
        addressDelta,
      );
    final tagsDelta = ListPatchDelta.diff<String>(previous.tags, next.tags);
    if (tagsDelta.isNotEmpty) changes.patchMap[Profile$.tags] = tagsDelta;
    final scoresDelta = MapPatchDelta.diff<String, int>(
      previous.scores,
      next.scores,
    );
    if (scoresDelta.isNotEmpty) changes.patchMap[Profile$.scores] = scoresDelta;
    if (previous.previousAddress != null && next.previousAddress != null) {
      final nested = AddressPatch.diff(
        previous.previousAddress!,
        next.previousAddress!,
      );
      if (nested.isNotEmpty)
        changes.patchMap[Profile$.previousAddress] =
            PatchNested<Address, AddressPatch>(nested);
    }
    if (previous.previousAddress == null || next.previousAddress == null) {
      if (previous.previousAddress != next.previousAddress)
        changes.patchMap[Profile$.previousAddress] = next.previousAddress;
    }
    return changes;
  }

  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (patchMap.containsKey(Profile$.id)) wire['id'] = patchMap[Profile$.id];
    if (patchMap.containsKey(Profile$.displayName))
      wire['displayName'] = patchMap[Profile$.displayName];
    if (patchMap.containsKey(Profile$.address))
      wire['address'] = patchMap[Profile$.address];
    if (patchMap.containsKey(Profile$.tags))
      wire['tags'] = patchMap[Profile$.tags] is ListPatchDelta<String>
          ? (patchMap[Profile$.tags] as ListPatchDelta<String>).toWire()
          : patchMap[Profile$.tags];
    if (patchMap.containsKey(Profile$.scores))
      wire['scores'] = patchMap[Profile$.scores] is MapPatchDelta<String, int>
          ? (patchMap[Profile$.scores] as MapPatchDelta<String, int>).toWire()
          : patchMap[Profile$.scores];
    if (patchMap.containsKey(Profile$.previousAddress))
      wire['previousAddress'] = patchMap[Profile$.previousAddress];
    return wire;
  }

  ProfilePatch withId(String? value) {
    patchMap[Profile$.id] = value;
    return this;
  }

  ProfilePatch withDisplayName(String? value) {
    patchMap[Profile$.displayName] = value;
    return this;
  }

  ProfilePatch withAddress(Address? value) {
    patchMap[Profile$.address] = value;
    return this;
  }

  ProfilePatch withAddressPatch(AddressPatch patch) {
    patchMap[Profile$.address] = patch;
    return this;
  }

  ProfilePatch withAddressPatchFunc(AddressPatch Function(AddressPatch) patch) {
    patchMap[Profile$.address] = (dynamic current) {
      return patch(AddressPatch()).applyTo(current as Address);
    };
    return this;
  }

  ProfilePatch withTags(List<String>? value) {
    patchMap[Profile$.tags] = value;
    return this;
  }

  ProfilePatch withScores(Map<String, int>? value) {
    patchMap[Profile$.scores] = value;
    return this;
  }

  ProfilePatch withPreviousAddress(Address? value) {
    patchMap[Profile$.previousAddress] = value;
    return this;
  }

  ProfilePatch withPreviousAddressPatch(AddressPatch patch) {
    patchMap[Profile$.previousAddress] = patch;
    return this;
  }

  ProfilePatch withPreviousAddressPatchFunc(
    AddressPatch Function(AddressPatch) patch,
  ) {
    patchMap[Profile$.previousAddress] = (dynamic current) {
      return patch(AddressPatch()).applyTo(current as Address);
    };
    return this;
  }
}
// GOLDEN-PROFILE-PATCH-END
