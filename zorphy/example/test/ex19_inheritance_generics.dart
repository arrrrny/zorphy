import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'ex19_inheritance_generics.zorphy.dart';

@zorphy
abstract class $$A {}

@zorphy
abstract class $$B implements $$A {}

@zorphy
abstract class $$C<TBatchItem extends $$A> {
  List<TBatchItem> get items;
}

@zorphy
abstract class $$D {
  List<$$B> get items;
}

@zorphy
abstract class $E
    implements //
        $$C<$$B>,
        $$D {
  List<$$B> get items;
}
