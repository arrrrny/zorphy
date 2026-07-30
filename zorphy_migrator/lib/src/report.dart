import 'model.dart';

/// Renders the markdown migration report.
class MigrationReport {
  final List<ConvertedClass> converted;
  final List<ManualItem> manualItems;

  MigrationReport({required this.converted, required this.manualItems});

  String toMarkdown() {
    final sb = StringBuffer()
      ..writeln('# Freezed → Zorphy Migration Report')
      ..writeln()
      ..writeln('## Converted classes (${converted.length})')
      ..writeln();

    if (converted.isEmpty) {
      sb.writeln('_None._');
    } else {
      for (final c in converted) {
        final notes = c.notes.isEmpty ? '' : ' — ${c.notes.join('; ')}';
        sb.writeln('- `${c.className}` (${c.filePath})$notes');
      }
    }

    sb
      ..writeln()
      ..writeln('## Needs manual attention (${manualItems.length})')
      ..writeln();

    if (manualItems.isEmpty) {
      sb.writeln('_None — clean migration._');
    } else {
      for (final m in manualItems) {
        sb.writeln(
          '- `${m.filePath}:${m.line}` — `${m.construct}`: ${m.reason}',
        );
      }
    }

    sb
      ..writeln()
      ..writeln('## Next steps')
      ..writeln()
      ..writeln('1. Remove `freezed` and `freezed_annotation` from pubspec.yaml '
          'and add `zorphy` (dev) + `zorphy_annotation`.')
      ..writeln('2. Delete all `*.freezed.dart` files '
          '(and stale `*.g.dart` for converted classes).')
      ..writeln('3. Update `part` directives: drop `.freezed.dart`, '
          'keep `.g.dart` only when `generateJson: true` was emitted.')
      ..writeln('4. Replace `when`/`map` calls with Dart 3 `switch` '
          'expressions on the sealed base.')
      ..writeln('5. Run `dart run build_runner build '
          '--delete-conflicting-outputs`, then `dart analyze`.');

    return sb.toString();
  }
}

/// A class the migrator converted successfully.
class ConvertedClass {
  final String className;
  final String filePath;
  final List<String> notes;

  const ConvertedClass(this.className, this.filePath, [this.notes = const []]);
}
