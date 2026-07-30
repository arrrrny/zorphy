import 'dart:io';

import 'package:zorphy_migrator/src/freezed_detector.dart';

void main() async {
  final f = File('/tmp/mig_scratch/input.dart').absolute.path;
  final models = await FreezedDetector().detect([f]);
  // ignore: avoid_print
  print('detected=${models.length}');
  for (final m in models) {
    // ignore: avoid_print
    print('name=${m.name} span=${m.spanStart}-${m.spanEnd} migratable=${m.isMigratable}');
  }
}

