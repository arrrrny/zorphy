import 'dart:io';

import 'package:zorphy_migrator/src/cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await MigratorCli().run(args);
}
