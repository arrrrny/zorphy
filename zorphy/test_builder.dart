import 'dart:io';
import 'package:build/build.dart';
import 'package:zorphy/builder.dart';

void main() async {
  print('Creating zorphy builder...');
  final builder = zorphyBuilder(BuilderOptions.empty);
  print('Builder created: $builder');
  print('Builder buildExtensions: ${builder.buildExtensions}');
}
