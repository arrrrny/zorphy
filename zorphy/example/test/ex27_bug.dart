import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'ex27_bug.zorphy.dart';

///HASHCODE ERROR AGAIN

@Zorphy()
abstract class $UserLectureInfoPopupVM {
  String get lectureId;
  bool get isExcluded;
}

@Zorphy()
abstract class $UserLectureInfoPopupVM_worstWords
    implements $UserLectureInfoPopupVM {
  String get worstWordDue;
  String get stageOfStages;
}
