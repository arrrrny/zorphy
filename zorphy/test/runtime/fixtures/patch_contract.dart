import 'package:zorphy_annotation/zorphy.dart';

const _unset = Object();

enum PatchProbeStatus { active, paused }

final class ProbeAddress {
  const ProbeAddress({required this.street, required this.city});

  final String street;
  final String city;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProbeAddress && other.street == street && other.city == city;

  @override
  int get hashCode => Object.hash(street, city);
}

final class PatchProbe {
  const PatchProbe({
    required this.id,
    required this.title,
    required this.tags,
    required this.scores,
    required this.counts,
    required this.status,
    required this.address,
    this.previousAddress,
  });

  final String id;
  final String title;
  final List<String> tags;
  final Map<String, int> scores;
  final Map<int, int> counts;
  final PatchProbeStatus status;
  final ProbeAddress address;
  final ProbeAddress? previousAddress;

  PatchProbe copyWith({
    String? id,
    String? title,
    List<String>? tags,
    Map<String, int>? scores,
    Map<int, int>? counts,
    PatchProbeStatus? status,
    ProbeAddress? address,
    Object? previousAddress = _unset,
  }) {
    return PatchProbe(
      id: id ?? this.id,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      scores: scores ?? this.scores,
      counts: counts ?? this.counts,
      status: status ?? this.status,
      address: address ?? this.address,
      previousAddress: identical(previousAddress, _unset)
          ? this.previousAddress
          : previousAddress as ProbeAddress?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchProbe &&
          other.id == id &&
          other.title == title &&
          zorphyCollectionEquals(other.tags, tags) &&
          zorphyCollectionEquals(other.scores, scores) &&
          zorphyCollectionEquals(other.counts, counts) &&
          other.status == status &&
          other.address == address &&
          other.previousAddress == previousAddress;

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    zorphyCollectionHash(tags),
    zorphyCollectionHash(scores),
    zorphyCollectionHash(counts),
    status,
    address,
    previousAddress,
  ]);
}

// GOLDEN-PATCH-CONTRACT-START
final class PatchProbePatch implements ZorphyPatch<PatchProbe> {
  PatchProbePatch({
    PatchValue<String> id = const PatchValue.unchanged(),
    PatchValue<String> title = const PatchValue.unchanged(),
    PatchValue<List<String>> tags = const PatchValue.unchanged(),
    PatchValue<Map<String, int>> scores = const PatchValue.unchanged(),
    PatchValue<Map<int, int>> counts = const PatchValue.unchanged(),
    PatchValue<PatchProbeStatus> status = const PatchValue.unchanged(),
    PatchValue<ProbeAddress> address = const PatchValue.unchanged(),
    PatchValue<ProbeAddress?> previousAddress = const PatchValue.unchanged(),
  }) : id = id,
       title = title,
       tags = tags,
       scores = scores,
       counts = counts,
       status = status,
       address = address,
       previousAddress = previousAddress;

  final PatchValue<String> id;

  final PatchValue<String> title;

  final PatchValue<List<String>> tags;

  final PatchValue<Map<String, int>> scores;

  final PatchValue<Map<int, int>> counts;

  final PatchValue<PatchProbeStatus> status;

  final PatchValue<ProbeAddress> address;

  final PatchValue<ProbeAddress?> previousAddress;

  PatchProbePatch withId(String value) {
    return PatchProbePatch(
      id: PatchValue.set(value),
      title: this.title,
      tags: this.tags,
      scores: this.scores,
      counts: this.counts,
      status: this.status,
      address: this.address,
      previousAddress: this.previousAddress,
    );
  }

  PatchProbePatch withTitle(String value) {
    return PatchProbePatch(
      id: this.id,
      title: PatchValue.set(value),
      tags: this.tags,
      scores: this.scores,
      counts: this.counts,
      status: this.status,
      address: this.address,
      previousAddress: this.previousAddress,
    );
  }

  PatchProbePatch withTags(List<String> value) {
    return PatchProbePatch(
      id: this.id,
      title: this.title,
      tags: PatchValue.set(value),
      scores: this.scores,
      counts: this.counts,
      status: this.status,
      address: this.address,
      previousAddress: this.previousAddress,
    );
  }

  PatchProbePatch withScores(Map<String, int> value) {
    return PatchProbePatch(
      id: this.id,
      title: this.title,
      tags: this.tags,
      scores: PatchValue.set(value),
      counts: this.counts,
      status: this.status,
      address: this.address,
      previousAddress: this.previousAddress,
    );
  }

  PatchProbePatch withCounts(Map<int, int> value) {
    return PatchProbePatch(
      id: this.id,
      title: this.title,
      tags: this.tags,
      scores: this.scores,
      counts: PatchValue.set(value),
      status: this.status,
      address: this.address,
      previousAddress: this.previousAddress,
    );
  }

  PatchProbePatch withStatus(PatchProbeStatus value) {
    return PatchProbePatch(
      id: this.id,
      title: this.title,
      tags: this.tags,
      scores: this.scores,
      counts: this.counts,
      status: PatchValue.set(value),
      address: this.address,
      previousAddress: this.previousAddress,
    );
  }

  PatchProbePatch withAddress(ProbeAddress value) {
    return PatchProbePatch(
      id: this.id,
      title: this.title,
      tags: this.tags,
      scores: this.scores,
      counts: this.counts,
      status: this.status,
      address: PatchValue.set(value),
      previousAddress: this.previousAddress,
    );
  }

  PatchProbePatch withPreviousAddress(ProbeAddress? value) {
    return PatchProbePatch(
      id: this.id,
      title: this.title,
      tags: this.tags,
      scores: this.scores,
      counts: this.counts,
      status: this.status,
      address: this.address,
      previousAddress: PatchValue.set(value),
    );
  }

  @override
  bool get isEmpty {
    return id.isUnchanged &&
        title.isUnchanged &&
        tags.isUnchanged &&
        scores.isUnchanged &&
        counts.isUnchanged &&
        status.isUnchanged &&
        address.isUnchanged &&
        previousAddress.isUnchanged;
  }

  @override
  bool get isNotEmpty {
    return !isEmpty;
  }

  @override
  PatchProbe apply(covariant PatchProbe target) {
    if (isEmpty) return target;
    return target.copyWith(
      id: this.id.isUnchanged ? target.id : this.id.valueOrNull,
      title: this.title.isUnchanged ? target.title : this.title.valueOrNull,
      tags: this.tags.isUnchanged ? target.tags : this.tags.valueOrNull,
      scores: this.scores.isUnchanged ? target.scores : this.scores.valueOrNull,
      counts: this.counts.isUnchanged ? target.counts : this.counts.valueOrNull,
      status: this.status.isUnchanged ? target.status : this.status.valueOrNull,
      address: this.address.isUnchanged
          ? target.address
          : this.address.valueOrNull,
      previousAddress: this.previousAddress.isUnchanged
          ? target.previousAddress
          : this.previousAddress.valueOrNull,
    );
  }

  @override
  PatchProbePatch compose(ZorphyPatch<PatchProbe> next) {
    if (next.isEmpty) return this;
    if (next is! PatchProbePatch) {
      throw ArgumentError.value(
        next,
        'next',
        'PatchProbePatch cannot compose ${next.runtimeType}',
      );
    }
    if (isEmpty) return next;
    return PatchProbePatch(
      id: next.id.isUnchanged ? this.id : next.id,
      title: next.title.isUnchanged ? this.title : next.title,
      tags: next.tags.isUnchanged ? this.tags : next.tags,
      scores: next.scores.isUnchanged ? this.scores : next.scores,
      counts: next.counts.isUnchanged ? this.counts : next.counts,
      status: next.status.isUnchanged ? this.status : next.status,
      address: next.address.isUnchanged ? this.address : next.address,
      previousAddress: next.previousAddress.isUnchanged
          ? this.previousAddress
          : next.previousAddress,
    );
  }

  @override
  PatchProbePatch invert(PatchProbe before) {
    return PatchProbePatch(
      id: this.id.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.id),
      title: this.title.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.title),
      tags: this.tags.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.tags),
      scores: this.scores.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.scores),
      counts: this.counts.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.counts),
      status: this.status.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.status),
      address: this.address.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.address),
      previousAddress: this.previousAddress.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.previousAddress),
    );
  }

  @override
  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (this.id.isSet) wire['id'] = this.id.valueOrNull;
    if (this.title.isSet) wire['title'] = this.title.valueOrNull;
    if (this.tags.isSet)
      wire['tags'] = this.tags.valueOrNull?.map((element) => element).toList();
    if (this.scores.isSet)
      wire['scores'] = this.scores.valueOrNull?.map(
        (key, value) => MapEntry(key, value),
      );
    if (this.counts.isSet)
      wire['counts'] = this.counts.valueOrNull?.map(
        (key, value) => MapEntry(key, value),
      );
    if (this.status.isSet) wire['status'] = this.status.valueOrNull?.name;
    if (this.address.isSet) wire['address'] = this.address.valueOrNull;
    if (this.previousAddress.isSet)
      wire['previousAddress'] = this.previousAddress.valueOrNull;
    return wire;
  }

  Map<String, Object?> toEnvelope({Object? principalKey}) {
    return <String, Object?>{
      'entityType': 'PatchProbe',
      'patchKind': 'PatchProbe',
      'principalKey': principalKey,
      'ops': toWire(),
    };
  }

  static PatchProbePatch diff(PatchProbe previous, PatchProbe next) {
    if (identical(previous, next)) return PatchProbePatch();
    var changes = PatchProbePatch();
    if (previous.id != next.id) changes = changes.withId(next.id);
    if (previous.title != next.title) changes = changes.withTitle(next.title);
    if (!zorphyCollectionEquals(previous.tags, next.tags))
      changes = changes.withTags(next.tags);
    if (!zorphyCollectionEquals(previous.scores, next.scores))
      changes = changes.withScores(next.scores);
    if (!zorphyCollectionEquals(previous.counts, next.counts))
      changes = changes.withCounts(next.counts);
    if (previous.status != next.status)
      changes = changes.withStatus(next.status);
    if (previous.address != next.address)
      changes = changes.withAddress(next.address);
    if (previous.previousAddress != next.previousAddress)
      changes = changes.withPreviousAddress(next.previousAddress);
    return changes;
  }

  static ZorphyBoundaryResult<PatchProbePatch> fromWire(
    Map<String, Object?> raw,
  ) {
    final violations = <FieldViolation>[];
    final ops = ZorphyPatchWire.opsOf(raw, '', violations);
    final prefix = ZorphyPatchWire.opsPathOf(raw);
    PatchValue<String>? idValue;
    if (ops != null && ops.containsKey('id')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['id'],
        '$prefix/id',
        violations,
      );
      idValue = (() {
        final idDecoded = ZorphyPatchWire.as<String>(
          rawValue,
          '$prefix/id',
          violations,
        );
        return idDecoded == null ? null : PatchValue<String>.set(idDecoded);
      })();
    }
    PatchValue<String>? titleValue;
    if (ops != null && ops.containsKey('title')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['title'],
        '$prefix/title',
        violations,
      );
      titleValue = (() {
        final titleDecoded = ZorphyPatchWire.as<String>(
          rawValue,
          '$prefix/title',
          violations,
        );
        return titleDecoded == null
            ? null
            : PatchValue<String>.set(titleDecoded);
      })();
    }
    PatchValue<List<String>>? tagsValue;
    if (ops != null && ops.containsKey('tags')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['tags'],
        '$prefix/tags',
        violations,
      );
      tagsValue = (() {
        final tagsDecoded = ZorphyPatchWire.listValue<String>(
          rawValue,
          '$prefix/tags',
          violations,
          (element, elementPath, violations) =>
              ZorphyPatchWire.as<String>(element, elementPath, violations),
        );
        return tagsDecoded == null
            ? null
            : PatchValue<List<String>>.set(tagsDecoded);
      })();
    }
    PatchValue<Map<String, int>>? scoresValue;
    if (ops != null && ops.containsKey('scores')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['scores'],
        '$prefix/scores',
        violations,
      );
      scoresValue = (() {
        final scoresDecoded = ZorphyPatchWire.mapValue<String, int>(
          rawValue,
          '$prefix/scores',
          violations,
          decodeKey: (key, keyPath, violations) =>
              ZorphyPatchWire.as<String>(key, keyPath, violations),
          decodeValue: (entry, entryPath, violations) =>
              ZorphyPatchWire.as<int>(entry, entryPath, violations),
        );
        return scoresDecoded == null
            ? null
            : PatchValue<Map<String, int>>.set(scoresDecoded);
      })();
    }
    PatchValue<Map<int, int>>? countsValue;
    if (ops != null && ops.containsKey('counts')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['counts'],
        '$prefix/counts',
        violations,
      );
      countsValue = (() {
        final countsDecoded = ZorphyPatchWire.mapValue<int, int>(
          rawValue,
          '$prefix/counts',
          violations,
          decodeKey: (key, keyPath, violations) =>
              ZorphyPatchWire.as<int>(key, keyPath, violations),
          decodeValue: (entry, entryPath, violations) =>
              ZorphyPatchWire.as<int>(entry, entryPath, violations),
        );
        return countsDecoded == null
            ? null
            : PatchValue<Map<int, int>>.set(countsDecoded);
      })();
    }
    PatchValue<PatchProbeStatus>? statusValue;
    if (ops != null && ops.containsKey('status')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['status'],
        '$prefix/status',
        violations,
      );
      statusValue = (() {
        final statusDecoded = ZorphyPatchWire.enumByName<PatchProbeStatus>(
          PatchProbeStatus.values,
          rawValue,
          '$prefix/status',
          violations,
        );
        return statusDecoded == null
            ? null
            : PatchValue<PatchProbeStatus>.set(statusDecoded);
      })();
    }
    PatchValue<ProbeAddress>? addressValue;
    if (ops != null && ops.containsKey('address')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['address'],
        '$prefix/address',
        violations,
      );
      addressValue = (() {
        final addressDecoded = ZorphyPatchWire.as<ProbeAddress>(
          rawValue,
          '$prefix/address',
          violations,
        );
        return addressDecoded == null
            ? null
            : PatchValue<ProbeAddress>.set(addressDecoded);
      })();
    }
    PatchValue<ProbeAddress?>? previousAddressValue;
    if (ops != null && ops.containsKey('previousAddress')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['previousAddress'],
        '$prefix/previousAddress',
        violations,
      );
      previousAddressValue = (() {
        if (rawValue == null) return PatchValue<ProbeAddress?>.set(null);
        final previousAddressDecoded = ZorphyPatchWire.as<ProbeAddress>(
          rawValue,
          '$prefix/previousAddress',
          violations,
        );
        return previousAddressDecoded == null
            ? null
            : PatchValue<ProbeAddress?>.set(previousAddressDecoded);
      })();
    }
    if (violations.isNotEmpty) {
      return BoundaryErr<PatchProbePatch>(
        targetType: 'PatchProbePatch',
        violations: violations,
      );
    }
    return BoundaryOk<PatchProbePatch>(
      PatchProbePatch(
        id: idValue ?? const PatchValue<String>.unchanged(),
        title: titleValue ?? const PatchValue<String>.unchanged(),
        tags: tagsValue ?? const PatchValue<List<String>>.unchanged(),
        scores: scoresValue ?? const PatchValue<Map<String, int>>.unchanged(),
        counts: countsValue ?? const PatchValue<Map<int, int>>.unchanged(),
        status: statusValue ?? const PatchValue<PatchProbeStatus>.unchanged(),
        address: addressValue ?? const PatchValue<ProbeAddress>.unchanged(),
        previousAddress:
            previousAddressValue ?? const PatchValue<ProbeAddress?>.unchanged(),
      ),
    );
  }
}
// GOLDEN-PATCH-CONTRACT-END
