/// Canonical intent digest for `@ZorphyIntent` hierarchies (ISSUE-014, #189).
///
/// An intent is replayed across a trust boundary, so its identity must be a
/// pure function of its MEANING: the intent name plus its canonical field
/// values, and nothing else. Two nodes that carry the same intent name and the
/// same field values produce the same digest on every host, in every process,
/// on every run — that is what makes a replay verifiably a replay.
///
/// The canonical form is deliberately narrow:
///
/// * object keys are sorted alphabetically (byte-wise on their UTF-8 form), so
///   map iteration order cannot leak into the digest;
/// * no insignificant whitespace, and no separators that are not structural;
/// * strings are JSON-escaped, numbers keep their shortest round-trip form,
///   and `true`/`false`/`null` are their JSON literals.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The canonical-JSON + SHA-256 digest of one intent payload.
///
/// Generated `intentDigest()` methods call [compute] with their own
/// [intentName] and the intent's field values, so every leaf of a hierarchy
/// gets a digest over its OWN name — a `DeleteProductIntent` and an
/// `InspectProductIntent` carrying identical `productId` values never collide.
abstract final class ZorphyIntentDigest {
  /// The digest of [intentName] together with [fields].
  ///
  /// [fields] is the intent's payload as a name -> value map; nested maps and
  /// lists are canonicalized the same way, so a nested identity cannot depend
  /// on iteration order either.
  static String compute(String intentName, Map<String, Object?> fields) =>
      sha256.convert(utf8.encode(canonicalJson(intentName, fields))).toString();

  /// The canonical JSON payload the digest is taken over.
  ///
  /// Exposed because a replay can be diagnosed far more cheaply by diffing
  /// two payloads than by comparing two opaque hashes: the digest tells you
  /// THAT two intents differ, this tells you WHERE.
  static String canonicalJson(String intentName, Map<String, Object?> fields) =>
      _canonicalJson({'intentName': intentName, 'fields': fields});

  /// Canonicalizes [value] with alphabetically sorted object keys.
  static String _canonicalJson(Object? value) {
    if (value == null) return 'null';
    if (value is String) return jsonEncode(value);
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) {
      if (value is double && !value.isFinite) {
        throw ArgumentError.value(
          value,
          'value',
          'an intent field must be finite to have a canonical form',
        );
      }
      return value is int
          ? value.toString()
          : _canonicalDouble(value as double);
    }
    if (value is Map) {
      final keys = value.keys.map((k) => k as String).toList()..sort();
      return '{${keys.map((k) => '${jsonEncode(k)}:${_canonicalJson(value[k])}').join(',')}}';
    }
    if (value is Iterable) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    throw ArgumentError.value(
      value,
      'value',
      'an intent field must be JSON-encodable (null, bool, num, String, '
          'Map<String, Object?>, or a List of those)',
    );
  }

  /// Shortest round-trip form of a finite double, with `1.0` kept as `1.0`.
  ///
  /// `double.toString()` already yields the shortest representation that
  /// round-trips, and unlike `jsonEncode` it never emits exponent notation for
  /// an integral value — so `2.0` stays `2.0` and cannot canonicalize to the
  /// same bytes as the int `2`.
  static String _canonicalDouble(double value) {
    final text = value.toString();
    return text;
  }
}
