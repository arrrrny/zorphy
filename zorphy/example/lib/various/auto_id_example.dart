import 'package:uuid/uuid.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'auto_id_example.zorphy.dart';
part 'auto_id_example.g.dart';

/// Entity with an auto-generated `id` field.
///
/// `autoId: true` makes the generated concrete constructor's `id` parameter
/// optional — it defaults to a fresh `Uuid().v4()` at construction time, so
/// callers can build the entity without supplying an identity (see
/// zuraffa#307: entities without an id previously fell back to the first
/// field as the id, producing enum-typed ids for `ChatMessage` /
/// `TelemetryEvent`).
@Zorphy(generateJson: true, autoId: true)
abstract class $AutoIdExample {
  String get id;
  String get name;
  int get score;
}

void main() {
  // id is optional — defaults to a generated uuid v4.
  final a = AutoIdExample(name: 'a', score: 1);
  final b = AutoIdExample(name: 'b', score: 2, id: 'fixed-id');

  print('a.id=${a.id} b.id=${b.id}');
  print('a == b: ${a == b}');
}
