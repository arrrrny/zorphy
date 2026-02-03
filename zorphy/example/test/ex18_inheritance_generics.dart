import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'ex18_inheritance_generics.zorphy.dart';

// Trigger regeneration to test casting fix

//superclass
@zorphy
abstract class $A<T> {
  List<T> get batchItems;
}

//subclass of generic unrelated class X
@zorphy
abstract class $B implements $A<$X> {
  List<$X> get batchItems;
}

//unrelated class
@zorphy
abstract class $X {
  int get id;
}
