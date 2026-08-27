// Repro fixture for issue #105 — value-object entity with bare
// `Function?` callback fields (the form produced by the CLI when the
// user writes `--field "onLoad:!Function?"` without pinning down a
// signature).
//
// Mirrors the exact annotation shape from the issue:
//   zfa entity create -n ScriptHtmlTagAttributes --kind=value_object \
//     --field "type:String" --field "id:String?" \
//     --field "onLoad:!Function?" --field "onError:!Function?"
//
// The CLI writes `Function? get onLoad;` / `Function? get onError;`
// into the entity file. Before the #105 fix, the generator emitted
// these as concrete `final Function? onLoad;` / `final Function? onError;`
// on the `@JsonSerializable`-annotated class with no `@JsonKey`
// opt-out, and `json_serializable` then failed with
//   "Could not generate `fromJson` code for `onLoad`."
// leaving the `.g.dart` unwritten and the package uncompilable.
//
// After the fix: `_isFunctionType` recognizes the bare `Function` /
// `Function?` forms and `_effectiveJsonKeyForField` auto-emits
// `@JsonKey(includeFromJson: false, includeToJson: false)` on each
// callback field — exactly as it does for the fully-typed
// `void Function(...)?` form from #89.

import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_105_bare_function_field.zorphy.dart';
part 'issue_105_bare_function_field.g.dart';

@Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
abstract class $ScriptHtmlTagAttributes {
  String get type;
  String? get id;
  Function? get onLoad;
  Function? get onError;
}
