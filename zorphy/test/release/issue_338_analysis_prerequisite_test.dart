import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('README documents example generation before package-wide analysis', () {
    final readme = File('../README.md').readAsStringSync();
    const heading = '## Repository analysis';
    expect(readme, contains(heading));

    final section = readme.split(heading).last.split('\n## ').first;
    expect(section, contains('cd zorphy/example'));
    expect(section, contains('dart pub get'));
    expect(section, contains('dart run build_runner build'));
    expect(section, contains('dart analyze --fatal-infos'));

    final generationIndex = section.indexOf('dart run build_runner build');
    final analysisIndex = section.indexOf('dart analyze --fatal-infos');
    expect(generationIndex, isNonNegative);
    expect(analysisIndex, greaterThan(generationIndex));
  });
}
