// Runtime fixture for ISSUE-0229 (zorphy#229) — the real intermediate
// patch emission, exercised by test/runtime/intermediate_patch_test.dart.
//
// The GOLDEN-POLY-INTERMEDIATE region is BYTE-IDENTICAL to
// `PolymorphicPatchEmitter.emitIntermediatePatch`; regenerate it from
// that emitter when the emission changes on purpose. The root patch is
// reduced to the surface the intermediate extends.

import 'package:zorphy_annotation/zorphy.dart';

abstract class Event {
  const Event({required this.id});
  final String id;
}

abstract class SystemEvent extends Event {
  const SystemEvent({
    required super.id,
    required this.source,
    required this.payload,
  });

  final String source;
  final Object payload;
}

class DeployEvent extends SystemEvent {
  const DeployEvent({
    required super.id,
    required super.source,
    required super.payload,
  });

  @override
  String get payload => super.payload as String;

  DeployEvent copyWith({String? id, String? source, String? payload}) {
    return DeployEvent(
      id: id ?? this.id,
      source: source ?? this.source,
      payload: payload ?? this.payload,
    );
  }
}

class AlertEvent extends SystemEvent {
  const AlertEvent({
    required super.id,
    required super.source,
    required super.payload,
  });

  @override
  int get payload => super.payload as int;

  AlertEvent copyWith({String? id, String? source, int? payload}) {
    return AlertEvent(
      id: id ?? this.id,
      source: source ?? this.source,
      payload: payload ?? this.payload,
    );
  }
}

/// The minimal root surface the intermediate patch extends. The golden test
/// checks the emitted intermediate below byte-for-byte against
/// `PolymorphicPatchEmitter.emitIntermediatePatch`.
abstract class EventPatch implements ZorphyPatch<Event> {
  const EventPatch();

  PatchValue<String> get id;

  @override
  bool get isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Event apply(covariant Event target);

  @override
  EventPatch compose(covariant EventPatch next);

  @override
  EventPatch invert(Event before);

  @override
  Map<String, Object?> toWire();
}

// GOLDEN-POLY-INTERMEDIATE-START
class SystemEventPatch extends EventPatch {
  SystemEventPatch({
    PatchValue<String> id = const PatchValue.unchanged(),
    PatchValue<String> source = const PatchValue.unchanged(),
    PatchValue<Object> payload = const PatchValue.unchanged(),
  }) : id = id,
       source = source,
       payload = payload;

  @override
  final PatchValue<String> id;

  final PatchValue<String> source;

  final PatchValue<Object> payload;

  SystemEventPatch withId(String value) {
    return SystemEventPatch(
      id: PatchValue.set(value),
      source: this.source,
      payload: this.payload,
    );
  }

  SystemEventPatch withSource(String value) {
    return SystemEventPatch(
      id: this.id,
      source: PatchValue.set(value),
      payload: this.payload,
    );
  }

  SystemEventPatch withPayload(Object value) {
    return SystemEventPatch(
      id: this.id,
      source: this.source,
      payload: PatchValue.set(value),
    );
  }

  @override
  bool get isEmpty {
    return id.isUnchanged && source.isUnchanged && payload.isUnchanged;
  }

  @override
  bool get isNotEmpty {
    return !isEmpty;
  }

  @override
  SystemEvent apply(covariant SystemEvent target) {
    if (isEmpty) return target;
    if (target is DeployEvent) {
      return target.copyWith(
        id: this.id.isUnchanged ? target.id : this.id.valueOrNull as String,
        source: this.source.isUnchanged
            ? target.source
            : this.source.valueOrNull as String,
        payload: this.payload.isUnchanged
            ? target.payload
            : this.payload.valueOrNull as String,
      );
    }
    if (target is AlertEvent) {
      return target.copyWith(
        id: this.id.isUnchanged ? target.id : this.id.valueOrNull as String,
        source: this.source.isUnchanged
            ? target.source
            : this.source.valueOrNull as String,
        payload: this.payload.isUnchanged
            ? target.payload
            : this.payload.valueOrNull as int,
      );
    }
    throw ArgumentError.value(
      target,
      'target',
      'SystemEventPatch cannot apply to ${target.runtimeType}',
    );
  }

  @override
  EventPatch compose(covariant EventPatch next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    if (next is! SystemEventPatch) {
      throw ArgumentError.value(
        next,
        'next',
        'SystemEventPatch cannot compose ${next.runtimeType}',
      );
    }
    return SystemEventPatch(
      id: next.id.isUnchanged ? this.id : next.id,
      source: next.source.isUnchanged ? this.source : next.source,
      payload: next.payload.isUnchanged ? this.payload : next.payload,
    );
  }

  @override
  SystemEventPatch invert(Event before) {
    if (before is! SystemEvent) {
      throw ArgumentError.value(
        before,
        'before',
        'SystemEventPatch cannot invert ${before.runtimeType}',
      );
    }
    return SystemEventPatch(
      id: this.id.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.id),
      source: this.source.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.source),
      payload: this.payload.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.payload),
    );
  }

  @override
  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (this.id.isSet) wire['id'] = this.id.valueOrNull;
    if (this.source.isSet) wire['source'] = this.source.valueOrNull;
    if (this.payload.isSet) wire['payload'] = this.payload.valueOrNull;
    return wire;
  }

  Map<String, Object?> toEnvelope({Object? principalKey}) {
    return <String, Object?>{
      'entityType': 'SystemEvent',
      'patchKind': 'SystemEvent',
      'principalKey': principalKey,
      'ops': toWire(),
    };
  }

  static ZorphyBoundaryResult<SystemEventPatch> fromWire(
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
    PatchValue<String>? sourceValue;
    if (ops != null && ops.containsKey('source')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['source'],
        '$prefix/source',
        violations,
      );
      sourceValue = (() {
        final sourceDecoded = ZorphyPatchWire.as<String>(
          rawValue,
          '$prefix/source',
          violations,
        );
        return sourceDecoded == null
            ? null
            : PatchValue<String>.set(sourceDecoded);
      })();
    }
    PatchValue<Object>? payloadValue;
    if (ops != null && ops.containsKey('payload')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['payload'],
        '$prefix/payload',
        violations,
      );
      payloadValue = (() {
        final payloadDecoded = ZorphyPatchWire.as<Object>(
          rawValue,
          '$prefix/payload',
          violations,
        );
        return payloadDecoded == null
            ? null
            : PatchValue<Object>.set(payloadDecoded);
      })();
    }
    if (violations.isNotEmpty) {
      return BoundaryErr<SystemEventPatch>(
        targetType: 'SystemEventPatch',
        violations: violations,
      );
    }
    return BoundaryOk<SystemEventPatch>(
      SystemEventPatch(
        id: idValue ?? const PatchValue<String>.unchanged(),
        source: sourceValue ?? const PatchValue<String>.unchanged(),
        payload: payloadValue ?? const PatchValue<Object>.unchanged(),
      ),
    );
  }

  static SystemEventPatch diff(SystemEvent previous, SystemEvent next) {
    if (identical(previous, next)) return SystemEventPatch();
    var changes = SystemEventPatch();
    if (previous.id != next.id) changes = changes.withId(next.id);
    if (previous.source != next.source)
      changes = changes.withSource(next.source);
    if (previous.payload != next.payload)
      changes = changes.withPayload(next.payload);
    return changes;
  }
}
// GOLDEN-POLY-INTERMEDIATE-END
