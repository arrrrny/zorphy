// The generated class does not exist in the fixture; the detector only reads
// the text.
// ignore_for_file: undefined_class, undefined_function, undefined_getter
import 'package:zorphy_annotation/zorphy_annotation.dart';

@Zorphy(generatePatch: true, generateFilter: true, generateJson: true)
abstract class $LocalUse {
  String get name;
}

// Everything is consumed from inside this very file, including the
// instance-level `toJson()` a syntactic scan cannot attribute.
void consume(LocalUse value) {
  LocalUsePatch(name: 'x');
  LocalUseFields.name;
  value.toJson();
}
