import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'exchangeable_detector.dart';
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

  /// A `part of` directive, wherever it sits in the file.
  ///
  /// `multiLine` is load-bearing: without it `^` anchors at the start of the
  /// file only, so a part opening with a license header, a `// @dart=` line
  /// or any other comment is not recognised — and a generated part names
  /// every class in its library, which would make all of them look used.
  static final _sharedPartPattern = RegExp(r'^\s*part\s+of\s', multiLine: true);

  Future<int> run(List<String> arguments) async {
    final parser = ArgParser()
      ..addFlag(
        'dry-run',
        abbr: 'n',
        help: 'Print unified diff, write nothing (default).',
      )
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

    if (args['help'] as bool) {
      stdout.writeln(
        'Usage:\n'
        '  zorphy_migrator migrate <path> [--dry-run] [--apply] '
        '[--report <file>] [--fail-on-manual]\n',
      );
      return exitClean;
    }

    if (args.rest.length < 2 || args.rest.first != 'migrate') {
      stderr.writeln(
        'Usage: zorphy_migrator migrate <path> [--dry-run] [--apply] '
        '[--report <file>] [--fail-on-manual]',
      );
      return exitAnalysisError;
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
      final freezedModels = await FreezedDetector().detect(files);
      final exchangeableModels = await ExchangeableDetector().detect(files);
      models = [...freezedModels, ...exchangeableModels];
    } catch (e) {
      stderr.writeln('Analysis error: $e');
      return exitAnalysisError;
    }

    if (models.isEmpty && files.isNotEmpty) {
      // A wrong-scope invocation must not look like a clean migration.
      stderr.writeln(
        'WARNING: no @freezed or @ExchangeableObject/@ExchangeableEnum '
        'models found under $target — nothing to migrate. Is this the '
        'right directory?',
      );
      return exitManualItems;
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
        // Informational items ride along on converted models too (e.g. an
        // enum wire that needs consumer glue) — the conversion is safe, the
        // report still tells the reader what to check by hand.
        manual.addAll(m.informationalItems);
        if (m.isMigratable) {
          final notes = <String>[];
          if (m.dialect == ModelDialect.exchangeableObject) {
            notes.add('@ExchangeableObject');
          }
          if (m.dialect == ModelDialect.exchangeableEnum) {
            notes.add('@ExchangeableEnum');
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
      hasExchangeable: models.any((m) => m.dialect != ModelDialect.freezed),
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
        file.path
            .split(Platform.pathSeparator)
            .any((seg) => seg.startsWith('.') || seg == 'build');

    if (entity == FileSystemEntityType.file) {
      final f = File(target);
      if (f.path.endsWith('.dart') && !skip(f)) files.add(f.absolute.path);
    } else if (entity == FileSystemEntityType.directory) {
      // A package root's tests and integration tests consume generated
      // helpers too: a feature used only there still has to be generated, or
      // the suite stops compiling. Anything else is scanned as given. The set
      // keeps the root walk and the extra dirs from double-counting a file.
      final roots = <String>{target};
      if (File(p.join(target, 'pubspec.yaml')).existsSync()) {
        for (final extra in ['test', 'integration_test']) {
          final dir = p.join(target, extra);
          if (Directory(dir).existsSync()) roots.add(dir);
        }
      }
      for (final root in roots) {
        for (final e in Directory(root).listSync(recursive: true)) {
          if (e is File && e.path.endsWith('.dart') && !skip(e)) {
            files.add(e.absolute.path);
          }
        }
      }
    }
    // Shared parts (zorphy 3.0's `lib/_br_/<name>.part.dart`) are generated
    // code too, but no extension rule catches them — and scanning them makes
    // every class look used, because a generated part names all of them.
    // A file that cannot even be read is left in the scan: dropping it would
    // silently shrink the evidence `lean` decides on, and the read below
    // then fails inside the caller's handled `Analysis error:` path instead
    // of throwing from here, before anything has been printed.
    files.removeWhere((file) {
      if (file.split(Platform.pathSeparator).contains('_br_')) return true;
      final String head;
      try {
        head = File(file).readAsStringSync();
      } on FileSystemException {
        return false;
      }
      return _sharedPartPattern.hasMatch(head);
    });
    return files.toSet().toList()..sort();
  }
}
