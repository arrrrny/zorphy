// The generated class does not exist in the fixture; the detector only reads
// the text.
// ignore_for_file: undefined_class
import 'dart:convert';

import 'remote_json_model.dart';

// The only JSON usage is the instance call `toJson()` — no class-attributed
// symbol appears anywhere, yet generateJson must survive.
String encode(RemoteJsonModel model) => jsonEncode(model.toJson());
