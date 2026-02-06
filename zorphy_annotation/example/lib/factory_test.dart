import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'factory_test.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $TestWithFactory {
  String get id;

  // Factory constructor - concrete class should implement, not extend
  factory $TestWithFactory.create({required String id}) =>
      TestWithFactory(id: id);
}
