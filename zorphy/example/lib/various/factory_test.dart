import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'factory_test.zorphy.dart';
part 'factory_test.g.dart';

@Zorphy(generateJson: true, hidePublicConstructor: true)
abstract class $TestWithFactory {
  String get id;

  static TestWithFactory create({required String id}) =>
      TestWithFactory._(id: id);
}
