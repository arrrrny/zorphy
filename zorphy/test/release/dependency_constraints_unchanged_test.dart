import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

Map<String, String> _parseDependencies(
  YamlMap pubspec, [
  String key = 'dependencies',
]) {
  final deps = pubspec[key] as YamlMap?;
  if (deps == null) return <String, String>{};
  final result = <String, String>{};
  for (final entry in deps.entries) {
    final k = entry.key as String;
    final v = entry.value;
    if (v is String) {
      result[k] = v;
    }
  }
  return result;
}

void main() {
  group('2.5.0 dependency constraint pins', () {
    test(
      'zorphy and zorphy_annotation pin the 2.5.0 dependency constraints',
      () {
        final zorphyYaml =
            loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
        final annotationYaml = loadYaml(
          File('../zorphy_annotation/pubspec.yaml').readAsStringSync(),
        ) as YamlMap;

        final zorphyDeps = _parseDependencies(zorphyYaml);
        final zorphyDevDeps = _parseDependencies(
          zorphyYaml,
          'dev_dependencies',
        );
        final annotationDeps = _parseDependencies(annotationYaml);
        final annotationDevDeps = _parseDependencies(
          annotationYaml,
          'dev_dependencies',
        );

        final expectedZorphyDeps = <String, String>{
          'zorphy_annotation': '^2.5.0',
          'analyzer': '^14.0.0',
          'build': '>=4.0.4 <6.0.0',
          'source_gen': '^4.3.1',
          'dartx': '^1.2.0',
          'quiver': '^3.2.2',
          'path': '^1.9.1',
          'collection': '^1.19.1',
          'code_builder': '^4.10.0',
          'dart_style': '^3.1.1',
          'args': '^2.6.0',
          'glob': '^2.1.2',
          'watcher': '^1.1.1',
          'meta': '>=1.17.0 <2.0.0',
        };

        final expectedAnnotationDeps = <String, String>{
          'collection': '^1.19.1',
          'dartx': '^1.2.0',
          'json_annotation': '^4.12.0',
          'meta': '^1.17.0',
          'quiver': '^3.2.2',
        };

        final expectedZorphyDevDeps = <String, String>{
          'build_runner': '^2.17.1',
          'json_serializable': '^6.14.0',
          'json_annotation': '^4.12.0',
          'pub_semver': '^2.2.0',
          'test': '^1.31.1',
          'yaml': '^3.1.3',
        };

        final expectedAnnotationDevDeps = <String, String>{};

        expect(zorphyDeps, expectedZorphyDeps);
        expect(zorphyDevDeps, expectedZorphyDevDeps);
        expect(annotationDeps, expectedAnnotationDeps);
        expect(annotationDevDeps, expectedAnnotationDevDeps);
      },
    );
  });
}
