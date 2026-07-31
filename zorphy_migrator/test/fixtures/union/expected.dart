import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@Zorphy(explicitSubTypes: [$Ok, $Err])
abstract class $$Result {
}

@Zorphy()
abstract class $Ok implements $$Result {
  String get value;
}

@Zorphy()
abstract class $Err implements $$Result {
  String get message;
  int? get code;
}
