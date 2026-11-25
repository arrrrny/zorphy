import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@ZorphyValue()
abstract class $Box<T> {
  T get value;
  List<T>? get history;
}
