import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'nullable_test.g.dart';
part '../_br_/various/nullable_test.part.dart';

@Zorphy(generateJson: true)
abstract class $ErrorLog {
  String? get id;
  String get message;
  String get stackTrace;
  String get logLevel;
  String? get loggerName;
  String? get userId;
  String? get customerId;
  Map<String, dynamic>? get deviceInfo;
  String? get ipAddress;
  String? get appVersion;
  String? get platform;
  DateTime get timestamp;
  DateTime get createdAt;
}
