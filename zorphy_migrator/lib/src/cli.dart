import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'freezed_detector.dart';
import 'mapping.dart';
import 'model.dart';
import 'report.dart';
import 'rewriter.dart';

/// Exit codes: 0 = clean, 1 = manual items present, 2 = analysis error.
class MigratorCli {
  static const exitClean = 0;
  static const exitManualItems = 1;
  static const exitAnalysisError = 2;

  static final _generatedFilePattern = RegExp(
    r'\.(freezed|g|zorphy|zorphy2)\.dart$',
  );

  Future<int> run(List<String> arguments) async {
    final parser = ArgParser()
      ..addFlag('dry-run', abbr: 'n', help: 'Print unified diff, write nothing (default).')
      ..addFlag('apply', abbr: 'a', help: 'Rewrite files in place.')
      ..addOption('report', abbr: 'r', help: 'Write markdown report to file.')
      ..addFlag(
        'fail-on-manual',
        help: 'Exit 1 when any construct needs manual attention.',
      )
      ..addFlag('help', abbr: 'h', negatable: false);

    final ArgResults args;
    try {
      args = parser.parse(arguments);
    } on FormatException catch (e) {
      stderr.writeln(e.message);
      return exitAnalysisError;
    }

    if (args['help'] as bool || args.rest.length < 2 || args.rest.first != 'migrate') {
      stdout.writeln(
        'Usage: zorphy_migrator migrate <path> [--dry-run] [--apply] '
        '[--report <file>] [--fail-on-manual]',
      );
      return args['help'] as bool ? exitClean : exitAnalysisError;
    }

    final target = args.rest[1];
    final apply = args['apply'] as bool;
    final reportPath = args['report'] as String?;
    final failOnManual = args['fail-on-manual'] as bool;

    final files = _collectDartFiles(target);
    if (files.isEmpty) {
      stderr.writeln('No migratable Dart files found under $target');
      return exitAnalysisError;
    }

    List<FreezedClassModel> models;
    try {
      models = await FreezedDetector().detect(files);
    } catch (e) {
      stderr.writeln('Analysis error: $e');
      return exitAnalysisError;
    }

    final renderer = ZorphyRenderer(
      siblingClassNames: models.map((m) => m.name).toSet(),
    );
    final rewriter = Rewriter();
    final converted = <ConvertedClass>[];
    final manual = <ManualItem>[];
    final diffs = StringBuffer();

    // Group models by file — the detector reports absolute paths while
    // `files` may be relative, so normalize both sides.
    final byFile = <String, List<FreezedClassModel>>{};
    for (final m in models) {
      byFile.putIfAbsent(p.normalize(m.filePath), () => []).add(m);
    }

    for (final entry in byFile.entries) {
      final file = entry.key;
      final fileModels = entry.value;
      final source = await File(file).readAsString();

      final replacements = replacementsFor(fileModels, renderer.render);
      for (final m in fileModels) {
        if (m.isMigratable) {
          final notes = <String>[];
          if (m.isLeanEligible && !m.isUnion) {
            notes.add('preset: ZorphyPreset.lean');
          }
          converted.add(ConvertedClass(m.name, file, notes));
        } else {
          manual.addAll(m.manualItems);
        }
      }

      if (replacements.isEmpty) continue;
      final revised = rewriter.applySpans(source, replacements);

      if (apply) {
        await File(file).writeAsString(revised);
      } else {
        diffs.write(rewriter.unifiedDiff(source, revised, p.relative(file)));
      }
    }

    if (!apply && diffs.isNotEmpty) {
      stdout.write(diffs);
    }

    final report = MigrationReport(
      converted: converted,
      manualItems: manual,
    );
    if (reportPath != null) {
      await File(reportPath).writeAsString(report.toMarkdown());
      stdout.writeln('Report written to $reportPath');
    }

    if (manual.isNotEmpty) {
      stderr.writeln(
        '${manual.length} construct(s) need manual attention '
        '${reportPath == null ? '(run with --report for details)' : '(see $reportPath)'}',
      );
      if (failOnManual) return exitManualItems;
    }
    return exitClean;
  }

  List<String> _collectDartFiles(String target) {
    final entity = FileSystemEntity.typeSync(target);
    final files = <String>[];

    bool skip(File file) =>
        _generatedFilePattern.hasMatch(file.path) ||
        file.path.split(Platform.pathSeparator).any(
          (seg) => seg.startsWith('.') || seg == 'build',
        );

    if (entity == FileSystemEntityType.file) {
      final f = File(target);
      if (f.path.endsWith('.dart') && !skip(f)) files.add(f.absolute.path);
    } else if (entity == FileSystemEntityType.directory) {
      for (final e in Directory(target).listSync(recursive: true)) {
        if (e is File && e.path.endsWith('.dart') && !skip(e)) {
          files.add(e.absolute.path);
        }
      }
    }
    files.sort();
    return files;
  }
}
