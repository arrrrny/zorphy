import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'ex41_inheritance_generics.zorphy.dart';

enum eEnumExample { unknown, non200ResponseCode }

@Zorphy()
abstract class $$A<T> {}

//sibling of C, subclass of A, with a generic property of type A
@Zorphy()
abstract class $B<T> implements $$A<T> {
  T get data;
}

//sibling of B, subclass of A
@Zorphy()
abstract class $C<T> implements $$A<T> {
  eEnumExample get failureCode;

  String get description;
}
