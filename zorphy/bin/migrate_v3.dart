#!/usr/bin/env dart

/// `dart run zorphy:migrate_v3` — v2 -> v3 AST migration codemod
/// (ISSUE-019, arrrrny/zorphy#194).
///
/// Walks the given file or directory, rewrites every v2 `@Zorphy` /
/// `@ZorphySealed` annotation and `.fromJson` / `.toJson` call site onto the
/// zero-preset v3 archetypes and wire codecs, strips the stale v2
/// `part '*.zorphy.dart';` / `part '*.g.dart';` directives, and prints a
/// unified-style summary. Dry-run by default; `--apply` rewrites files in
/// place and deletes the stale 2.x `<file>.zorphy.dart` parts from disk.
///
/// Usage:
///   dart run zorphy:migrate_v3 <path> [--apply]
///
/// Exit codes: 0 = clean (or dry-run completed), 2 = usage / IO error.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:zorphy/src/migration/v3_codemod.dart';

const _version = '3.0.0';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('apply', abbr: 'a', help: 'Rewrite files in place.')
    ..addFlag('version', help: 'Print the codemod version and exit.')
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults parsed;
  try {
    parsed = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(2);
  }

  if (parsed['version'] as bool) {
    stdout.writeln('zorphy migrate_v3 $_version');
    return;
  }
  if (parsed['help'] as bool || parsed.rest.isEmpty) {
    stdout.writeln(
      'Usage:\n'
      '  dart run zorphy:migrate_v3 <path> [--apply]\n\n'
      'Migrates v2 @Zorphy / @ZorphySealed annotations and .fromJson / '
      '.toJson\ncall sites to the zero-preset v3 archetypes and wire codecs. '
      'Dry-run by default.',
    );
    exit(parsed.rest.isEmpty && parsed['help'] == false ? 2 : 0);
  }

  final apply = parsed['apply'] as bool;
  final target = parsed.rest.first;
  final files = _collectDartFiles(target);
  final staleParts = _collectStalePartFiles(target);
  if (files.isEmpty && staleParts.isEmpty) {
    stderr.writeln('No Dart files found under $target');
    exit(2);
  }

  // First pass: discover every zorphy-generated type in the tree so codec
  // calls in files that do not carry the annotation are still in scope.
  // Without this, a `User.fromJson(...)` in a service file would be mistaken
  // for an unrelated serializer and silently left behind.
  final sources = <String, String>{};
  final knownTypes = <String>{};
  final knownEntityRoots = <String>{};
  final inheritanceEdges = <String, List<String>>{};
  for (final file in files) {
    final source = await File(file).readAsString();
    sources[file] = source;
    knownTypes.addAll(V3Codemod.zorphyTypesIn(source));
    knownEntityRoots.addAll(V3Codemod.entityRootsIn(source));
    // Cross-file inheritance edges let classification propagate through a
    // parent that itself inherits `id` from a known root (#238).
    inheritanceEdges.addAll(V3Codemod.inheritanceEdgesIn(source));
  }
  final codemod = V3Codemod(
    knownTypes: knownTypes,
    knownEntityRoots: knownEntityRoots,
    inheritanceEdges: inheritanceEdges,
  );

  var changed = 0;
  for (final file in files) {
    final source = sources[file]!;
    final migrated = codemod.transform(source, fileName: p.basename(file));
    if (migrated == source) continue;
    changed++;
    if (apply) {
      await File(file).writeAsString(migrated);
    } else {
      stdout.writeln('would migrate: ${p.relative(file)}');
    }
  }

  // The 2.x layout left a generated `<file>.zorphy.dart` beside every source
  // file; v3 attaches one shared part itself, so a dry run lists the stale
  // files and --apply deletes them from disk (#249).
  if (staleParts.isNotEmpty) {
    if (apply) {
      for (final part in staleParts) {
        await File(part).delete();
      }
      stdout.writeln(
        'Deleted ${staleParts.length} stale .zorphy.dart file(s).',
      );
    } else {
      for (final part in staleParts) {
        stdout.writeln('would delete: ${p.relative(part)}');
      }
    }
  }

  if (changed == 0 && staleParts.isEmpty) {
    stdout.writeln('Nothing to migrate — no v2 constructs found.');
    return;
  }
  if (changed > 0) {
    stdout.writeln(
      apply
          ? 'Migrated $changed file(s). Re-run build_runner to regenerate.'
          : 'Dry run — $changed file(s) would change. Re-run with --apply.',
    );
  }
}

/// Every stale 2.x generated part under [target]: exactly the generated files
/// [_collectDartFiles] skips as unprocessable are the ones #249 deletes.
List<String> _collectStalePartFiles(String target) {
  final entity = FileSystemEntity.typeSync(target);
  final files = <String>{};
  bool stale(File file) =>
      file.path.endsWith('.zorphy.dart') &&
      !file.path
          .split(Platform.pathSeparator)
          .any((seg) => seg.startsWith('.') || seg == 'build');

  if (entity == FileSystemEntityType.file) {
    final f = File(target);
    if (stale(f)) files.add(f.absolute.path);
  } else if (entity == FileSystemEntityType.directory) {
    for (final e in Directory(target).listSync(recursive: true)) {
      if (e is File && stale(e)) files.add(e.absolute.path);
    }
  }
  return files.toList()..sort();
}

List<String> _collectDartFiles(String target) {
  final entity = FileSystemEntity.typeSync(target);
  final files = <String>{};
  bool skip(File file) =>
      file.path.endsWith('.zorphy.dart') ||
      file.path.endsWith('.zorphy2.dart') ||
      file.path.endsWith('.g.dart') ||
      file.path
          .split(Platform.pathSeparator)
          .any((seg) => seg.startsWith('.') || seg == 'build');

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
  return files.toList()..sort();
}
