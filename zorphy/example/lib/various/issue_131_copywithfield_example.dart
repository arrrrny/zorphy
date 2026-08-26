import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_131_copywithfield_example.zorphy.dart';

/// Fixture for issue #131: `copyWithField(Field<E, T> field, T value)`.
///
/// Two entities exercise the copyWithField surface:
///
///   - `$WalkthroughStep` — the zuraffa toggle shape: a plain entity
///     with String, int, bool and nullable String fields. The generated
///     `WalkthroughStep` gets the non-generic
///     `copyWithField<T>(Field<WalkthroughStep, T> field, T value)`.
///
///   - `$ProgressBox<T>` — a generic entity whose class type parameter
///     is named `T`, forcing the generator to rename the method's own
///     value type parameter (it cannot shadow the class's `T` inside
///     `Field<ProgressBox<T>, ...>`).
@zorphy
abstract class $WalkthroughStep {
  String get id;
  String get title;
  int get position;
  bool get completed;
  String? get note;
}

@zorphy
abstract class $ProgressBox<T> {
  T? get value;
  String get label;
}
