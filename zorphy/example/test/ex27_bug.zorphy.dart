// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex27_bug.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

///HASHCODE ERROR AGAIN
class UserLectureInfoPopupVM extends $UserLectureInfoPopupVM {
  @override
  final String lectureId;
  @override
  final bool isExcluded;

  UserLectureInfoPopupVM({
    required this.lectureId,
    required this.isExcluded,
  });

  UserLectureInfoPopupVM copyWith({
    String? lectureId,
    bool? isExcluded,
  }) {
    return UserLectureInfoPopupVM(
      lectureId: lectureId ?? this.lectureId,
      isExcluded: isExcluded ?? this.isExcluded,
    );
  }

  UserLectureInfoPopupVM copyWithUserLectureInfoPopupVM({
    String? lectureId,
    bool? isExcluded,
  }) {
    return copyWith(
      lectureId: lectureId,
      isExcluded: isExcluded,
    );
  }

  UserLectureInfoPopupVM patchWithUserLectureInfoPopupVM({
    UserLectureInfoPopupVMPatch? patchInput,
  }) {
    final _patcher = patchInput ?? UserLectureInfoPopupVMPatch();
    final _patchMap = _patcher.toPatch();
    return UserLectureInfoPopupVM(
        lectureId: _patchMap.containsKey(UserLectureInfoPopupVM$.lectureId)
            ? (_patchMap[UserLectureInfoPopupVM$.lectureId] is Function)
                ? _patchMap[UserLectureInfoPopupVM$.lectureId](this.lectureId)
                : _patchMap[UserLectureInfoPopupVM$.lectureId]
            : this.lectureId,
        isExcluded: _patchMap.containsKey(UserLectureInfoPopupVM$.isExcluded)
            ? (_patchMap[UserLectureInfoPopupVM$.isExcluded] is Function)
                ? _patchMap[UserLectureInfoPopupVM$.isExcluded](this.isExcluded)
                : _patchMap[UserLectureInfoPopupVM$.isExcluded]
            : this.isExcluded);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserLectureInfoPopupVM &&
        lectureId == other.lectureId &&
        isExcluded == other.isExcluded;
  }

  @override
  int get hashCode {
    return Object.hash(this.lectureId, this.isExcluded);
  }

  @override
  String toString() {
    return 'UserLectureInfoPopupVM(' +
        'lectureId: ${lectureId}' +
        ', ' +
        'isExcluded: ${isExcluded})';
  }
}

enum UserLectureInfoPopupVM$ { lectureId, isExcluded }

class UserLectureInfoPopupVMPatch implements Patch<UserLectureInfoPopupVM> {
  final Map<UserLectureInfoPopupVM$, dynamic> _patch = {};

  static UserLectureInfoPopupVMPatch create([Map<String, dynamic>? diff]) {
    final patch = UserLectureInfoPopupVMPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue =
              UserLectureInfoPopupVM$.values.firstWhere((e) => e.name == key);
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static UserLectureInfoPopupVMPatch fromPatch(
      Map<UserLectureInfoPopupVM$, dynamic> patch) {
    final _patch = UserLectureInfoPopupVMPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<UserLectureInfoPopupVM$, dynamic> toPatch() => Map.from(_patch);

  UserLectureInfoPopupVM applyTo(UserLectureInfoPopupVM entity) {
    return entity.patchWithUserLectureInfoPopupVM(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static UserLectureInfoPopupVMPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  UserLectureInfoPopupVMPatch withLectureId(String? value) {
    _patch[UserLectureInfoPopupVM$.lectureId] = value;
    return this;
  }

  UserLectureInfoPopupVMPatch withIsExcluded(bool? value) {
    _patch[UserLectureInfoPopupVM$.isExcluded] = value;
    return this;
  }
}

extension UserLectureInfoPopupVMCompareE on UserLectureInfoPopupVM {
  Map<String, dynamic> compareToUserLectureInfoPopupVM(
      UserLectureInfoPopupVM other) {
    final Map<String, dynamic> diff = {};

    if (lectureId != other.lectureId) {
      diff['lectureId'] = () => other.lectureId;
    }
    if (isExcluded != other.isExcluded) {
      diff['isExcluded'] = () => other.isExcluded;
    }
    return diff;
  }
}

class UserLectureInfoPopupVM_worstWords
    extends $UserLectureInfoPopupVM_worstWords
    implements $UserLectureInfoPopupVM {
  @override
  final String lectureId;
  @override
  final bool isExcluded;
  @override
  final String worstWordDue;
  @override
  final String stageOfStages;

  UserLectureInfoPopupVM_worstWords({
    required this.lectureId,
    required this.isExcluded,
    required this.worstWordDue,
    required this.stageOfStages,
  });

  UserLectureInfoPopupVM_worstWords copyWith({
    String? lectureId,
    bool? isExcluded,
    String? worstWordDue,
    String? stageOfStages,
  }) {
    return UserLectureInfoPopupVM_worstWords(
      lectureId: lectureId ?? this.lectureId,
      isExcluded: isExcluded ?? this.isExcluded,
      worstWordDue: worstWordDue ?? this.worstWordDue,
      stageOfStages: stageOfStages ?? this.stageOfStages,
    );
  }

  UserLectureInfoPopupVM_worstWords copyWithUserLectureInfoPopupVM_worstWords({
    String? lectureId,
    bool? isExcluded,
    String? worstWordDue,
    String? stageOfStages,
  }) {
    return copyWith(
      lectureId: lectureId,
      isExcluded: isExcluded,
      worstWordDue: worstWordDue,
      stageOfStages: stageOfStages,
    );
  }

  UserLectureInfoPopupVM_worstWords patchWithUserLectureInfoPopupVM_worstWords({
    UserLectureInfoPopupVM_worstWordsPatch? patchInput,
  }) {
    final _patcher = patchInput ?? UserLectureInfoPopupVM_worstWordsPatch();
    final _patchMap = _patcher.toPatch();
    return UserLectureInfoPopupVM_worstWords(
        lectureId:
            _patchMap.containsKey(UserLectureInfoPopupVM_worstWords$.lectureId)
                ? (_patchMap[UserLectureInfoPopupVM_worstWords$.lectureId]
                        is Function)
                    ? _patchMap[UserLectureInfoPopupVM_worstWords$.lectureId](
                        this.lectureId)
                    : _patchMap[UserLectureInfoPopupVM_worstWords$.lectureId]
                : this.lectureId,
        isExcluded:
            _patchMap.containsKey(UserLectureInfoPopupVM_worstWords$.isExcluded)
                ? (_patchMap[UserLectureInfoPopupVM_worstWords$.isExcluded]
                        is Function)
                    ? _patchMap[UserLectureInfoPopupVM_worstWords$.isExcluded](
                        this.isExcluded)
                    : _patchMap[UserLectureInfoPopupVM_worstWords$.isExcluded]
                : this.isExcluded,
        worstWordDue: _patchMap
                .containsKey(UserLectureInfoPopupVM_worstWords$.worstWordDue)
            ? (_patchMap[UserLectureInfoPopupVM_worstWords$.worstWordDue]
                    is Function)
                ? _patchMap[UserLectureInfoPopupVM_worstWords$.worstWordDue](
                    this.worstWordDue)
                : _patchMap[UserLectureInfoPopupVM_worstWords$.worstWordDue]
            : this.worstWordDue,
        stageOfStages: _patchMap
                .containsKey(UserLectureInfoPopupVM_worstWords$.stageOfStages)
            ? (_patchMap[UserLectureInfoPopupVM_worstWords$.stageOfStages]
                    is Function)
                ? _patchMap[UserLectureInfoPopupVM_worstWords$.stageOfStages](
                    this.stageOfStages)
                : _patchMap[UserLectureInfoPopupVM_worstWords$.stageOfStages]
            : this.stageOfStages);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserLectureInfoPopupVM_worstWords &&
        lectureId == other.lectureId &&
        isExcluded == other.isExcluded &&
        worstWordDue == other.worstWordDue &&
        stageOfStages == other.stageOfStages;
  }

  @override
  int get hashCode {
    return Object.hash(
        this.lectureId, this.isExcluded, this.worstWordDue, this.stageOfStages);
  }

  @override
  String toString() {
    return 'UserLectureInfoPopupVM_worstWords(' +
        'lectureId: ${lectureId}' +
        ', ' +
        'isExcluded: ${isExcluded}' +
        ', ' +
        'worstWordDue: ${worstWordDue}' +
        ', ' +
        'stageOfStages: ${stageOfStages})';
  }
}

enum UserLectureInfoPopupVM_worstWords$ {
  lectureId,
  isExcluded,
  worstWordDue,
  stageOfStages
}

class UserLectureInfoPopupVM_worstWordsPatch
    implements Patch<UserLectureInfoPopupVM_worstWords> {
  final Map<UserLectureInfoPopupVM_worstWords$, dynamic> _patch = {};

  static UserLectureInfoPopupVM_worstWordsPatch create(
      [Map<String, dynamic>? diff]) {
    final patch = UserLectureInfoPopupVM_worstWordsPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = UserLectureInfoPopupVM_worstWords$.values
              .firstWhere((e) => e.name == key);
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static UserLectureInfoPopupVM_worstWordsPatch fromPatch(
      Map<UserLectureInfoPopupVM_worstWords$, dynamic> patch) {
    final _patch = UserLectureInfoPopupVM_worstWordsPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<UserLectureInfoPopupVM_worstWords$, dynamic> toPatch() =>
      Map.from(_patch);

  UserLectureInfoPopupVM_worstWords applyTo(
      UserLectureInfoPopupVM_worstWords entity) {
    return entity.patchWithUserLectureInfoPopupVM_worstWords(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static UserLectureInfoPopupVM_worstWordsPatch fromJson(
      Map<String, dynamic> json) {
    return create(json);
  }

  UserLectureInfoPopupVM_worstWordsPatch withLectureId(String? value) {
    _patch[UserLectureInfoPopupVM_worstWords$.lectureId] = value;
    return this;
  }

  UserLectureInfoPopupVM_worstWordsPatch withIsExcluded(bool? value) {
    _patch[UserLectureInfoPopupVM_worstWords$.isExcluded] = value;
    return this;
  }

  UserLectureInfoPopupVM_worstWordsPatch withWorstWordDue(String? value) {
    _patch[UserLectureInfoPopupVM_worstWords$.worstWordDue] = value;
    return this;
  }

  UserLectureInfoPopupVM_worstWordsPatch withStageOfStages(String? value) {
    _patch[UserLectureInfoPopupVM_worstWords$.stageOfStages] = value;
    return this;
  }
}

extension UserLectureInfoPopupVM_worstWordsCompareE
    on UserLectureInfoPopupVM_worstWords {
  Map<String, dynamic> compareToUserLectureInfoPopupVM_worstWords(
      UserLectureInfoPopupVM_worstWords other) {
    final Map<String, dynamic> diff = {};

    if (lectureId != other.lectureId) {
      diff['lectureId'] = () => other.lectureId;
    }
    if (isExcluded != other.isExcluded) {
      diff['isExcluded'] = () => other.isExcluded;
    }
    if (worstWordDue != other.worstWordDue) {
      diff['worstWordDue'] = () => other.worstWordDue;
    }
    if (stageOfStages != other.stageOfStages) {
      diff['stageOfStages'] = () => other.stageOfStages;
    }
    return diff;
  }
}
