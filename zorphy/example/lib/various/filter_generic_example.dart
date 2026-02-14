import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'filter_generic_example.zorphy.dart';

class Params {
  final String token;
  const Params(this.token);
}

@Zorphy(generateFilter: true)
abstract class $CreateParams<T, P> {
  T get data;
  P? get params;
}

void main() {
  final dataField = CreateParamsFields.data<String, Params>();
  final paramsField = CreateParamsFields.params<String, Params>();
  final filter = And([
    dataField.eq('payload'),
    paramsField.eq(const Params('token')),
  ]);
  print(filter.toJson());
}
