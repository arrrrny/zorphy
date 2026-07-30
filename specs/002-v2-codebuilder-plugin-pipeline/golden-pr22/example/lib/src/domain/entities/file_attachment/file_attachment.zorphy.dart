// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'file_attachment.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class FileAttachment extends Attachment {
  @override
  final String name;
  @override
  final String mimeType;
  @override
  final List<int> bytes;

  FileAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
  }) : super();

  FileAttachment copyWith({String? name, String? mimeType, List<int>? bytes}) {
    return FileAttachment(
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      bytes: bytes ?? this.bytes,
    );
  }

  FileAttachment copyWithFileAttachment({
    String? name,
    String? mimeType,
    List<int>? bytes,
  }) {
    return copyWith(name: name, mimeType: mimeType, bytes: bytes);
  }

  FileAttachment patchWithFileAttachment({FileAttachmentPatch? patchInput}) {
    final _patcher = patchInput ?? FileAttachmentPatch();
    final _patchMap = _patcher.patchMap;
    return FileAttachment(
      name: _patchMap.containsKey(FileAttachment$.name)
          ? (_patchMap[FileAttachment$.name] is Function)
                ? _patchMap[FileAttachment$.name](this.name)
                : (_patchMap[FileAttachment$.name] is Patch)
                ? _patchMap[FileAttachment$.name].applyTo(this.name)
                : _patchMap[FileAttachment$.name]
          : this.name,
      mimeType: _patchMap.containsKey(FileAttachment$.mimeType)
          ? (_patchMap[FileAttachment$.mimeType] is Function)
                ? _patchMap[FileAttachment$.mimeType](this.mimeType)
                : (_patchMap[FileAttachment$.mimeType] is Patch)
                ? _patchMap[FileAttachment$.mimeType].applyTo(this.mimeType)
                : _patchMap[FileAttachment$.mimeType]
          : this.mimeType,
      bytes: _patchMap.containsKey(FileAttachment$.bytes)
          ? (_patchMap[FileAttachment$.bytes] is Function)
                ? _patchMap[FileAttachment$.bytes](this.bytes)
                : (_patchMap[FileAttachment$.bytes] is Patch)
                ? _patchMap[FileAttachment$.bytes].applyTo(this.bytes)
                : _patchMap[FileAttachment$.bytes]
          : this.bytes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileAttachment &&
        name == other.name &&
        mimeType == other.mimeType &&
        bytes == other.bytes;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.mimeType, this.bytes);
  }

  @override
  String toString() {
    return 'FileAttachment(' +
        'name: ${name}' +
        ', ' +
        'mimeType: ${mimeType}' +
        ', ' +
        'bytes: ${bytes})';
  }

  /// Creates a [FileAttachment] instance from JSON
  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    if (json['__typename'] == null || json['__typename'] == "FileAttachment") {
      return _$FileAttachmentFromJson(json);
    } else if (json['__typename'] == "ImageFileAttachment") {
      return ImageFileAttachment.fromJson(json);
    }
    throw UnsupportedError(
      "The __typename '${json['__typename']}' is not supported by the $className.fromJson constructor.",
    );
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$FileAttachmentToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$FileAttachmentToJson(this);
    json['__typename'] = 'FileAttachment';
    return json;
  }
}

extension FileAttachmentPolymorphicE on FileAttachment {
  bool get isImageFileAttachment => this is ImageFileAttachment;
  ImageFileAttachment? get asImageFileAttachment =>
      this is ImageFileAttachment ? this as ImageFileAttachment : null;
}

enum FileAttachment$ { name, mimeType, bytes }

class FileAttachmentPatch extends PatchBase<FileAttachment, FileAttachment$> {
  FileAttachment applyTo(FileAttachment entity) {
    return entity.patchWithFileAttachment(patchInput: this);
  }

  FileAttachmentPatch withName(String? value) {
    patchMap[FileAttachment$.name] = value;
    return this;
  }

  FileAttachmentPatch withMimeType(String? value) {
    patchMap[FileAttachment$.mimeType] = value;
    return this;
  }

  FileAttachmentPatch withBytes(List<int>? value) {
    patchMap[FileAttachment$.bytes] = value;
    return this;
  }
}

/// Field descriptors for [FileAttachment] query construction
abstract final class FileAttachmentFields {
  static String _$getname(FileAttachment e) => e.name;
  static const name = Field<FileAttachment, String>('name', _$getname);
  static String _$getmimeType(FileAttachment e) => e.mimeType;
  static const mimeType = Field<FileAttachment, String>(
    'mimeType',
    _$getmimeType,
  );
  static List<int> _$getbytes(FileAttachment e) => e.bytes;
  static const bytes = Field<FileAttachment, List<int>>('bytes', _$getbytes);
}

extension FileAttachmentCompareE on FileAttachment {
  Map<String, dynamic> compareToFileAttachment(FileAttachment other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (mimeType != other.mimeType) {
      diff['mimeType'] = () => other.mimeType;
    }
    if (bytes != other.bytes) {
      diff['bytes'] = () => other.bytes;
    }
    return diff;
  }
}

extension FileAttachmentChangeToE on FileAttachment {
  ImageFileAttachment changeToImageFileAttachment({
    String? name,
    String? mimeType,
    List<int>? bytes,
  }) {
    final _patcher = ImageFileAttachmentPatch();
    if (name != null) {
      _patcher.withName(name);
    }
    if (mimeType != null) {
      _patcher.withMimeType(mimeType);
    }
    if (bytes != null) {
      _patcher.withBytes(bytes);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return ImageFileAttachment.fromJson(_json);
  }
}
