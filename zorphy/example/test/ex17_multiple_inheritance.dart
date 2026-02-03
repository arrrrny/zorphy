import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'ex17_multiple_inheritance.zorphy.dart';

///BatchLesson does xyz
@zorphy
abstract class $$Batch_Lesson {}

///Lesson Lectures does blah
///something else
@zorphy
abstract class $$Lesson_Lectures implements $$Batch_Lesson {}

///StagedLesson does h
@zorphy
abstract class $$Batch_Staged_Lesson implements $$Batch_Lesson {}

///This is my actual class
@zorphy
abstract class $Batch_Staged_Lesson_Lectures
    implements $$Batch_Staged_Lesson, $$Lesson_Lectures {}
