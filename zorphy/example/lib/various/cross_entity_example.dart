// Repro for issue #351: cross-entity reference generates InvalidType.
//
// `$ParentThing` is a normal Zorphy abstract entity. `$ChildThing` has a
// field whose declared type is the CONCRETE form `ParentThing?` (no `$`
// prefix) — this is the shape that survives the documented #349 workaround
// (`$ParentThing?` → `ParentThing?` hand-fix) and what the
// zikzak_inappwebview migration actually uses for sibling-entity refs.
//
// Expected after the fix: `child_thing.zorphy.dart` contains
//   final ParentThing? parent;
//   ChildThing({required ParentThing? this.parent});
// and the build succeeds (no `InvalidType`).
//
// Before the fix: `child_thing.zorphy.dart` contains
//   final InvalidType? parent;
//   ChildThing({required InvalidType? this.parent});
// and json_serializable fails on `InvalidType`.
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'cross_entity_example.zorphy.dart';
part 'cross_entity_example.g.dart';

@Zorphy(generateJson: true)
abstract class $ParentThing {
  String get name;
}

@Zorphy(generateJson: true)
abstract class $ChildThing {
  // CONCRETE cross-entity reference (no `$` prefix) — the issue #351 case.
  ParentThing? get parent;

  // Secondary finding: a `dynamic` field should NOT become
  // `required dynamic this.data` in the generated constructor.
  dynamic get data;
}
