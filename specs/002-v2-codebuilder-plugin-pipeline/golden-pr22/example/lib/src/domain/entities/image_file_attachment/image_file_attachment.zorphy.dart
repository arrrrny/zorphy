// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'image_file_attachment.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ImageFileAttachment extends FileAttachment implements Attachment {
  ImageFileAttachment({
    required String name,
    required String mimeType,
    required List<int> bytes,
  }) : super(name: name, mimeType: mimeType, bytes: bytes);

  ImageFileAttachment copyWith({
    String? name,
    String? mimeType,
    List<int>? bytes,
  }) {
    return ImageFileAttachment(
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      bytes: bytes ?? this.bytes,
    );
  }

  ImageFileAttachment copyWithImageFileAttachment({
    String? name,
    String? mimeType,
    List<int>? bytes,
  }) {
    return copyWith(name: name, mimeType: mimeType, bytes: bytes);
  }

  ImageFileAttachment copyWithFileAttachment({
    String? name,
    String? mimeType,
    List<int>? bytes,
  }) {
    return copyWith(name: name, mimeType: mimeType, bytes: bytes);
  }

  ImageFileAttachment patchWithImageFileAttachment({
    ImageFileAttachmentPatch? patchInput,
  }) {
    final _patcher = patchInput ?? ImageFileAttachmentPatch();
    final _patchMap = _patcher.patchMap;
    return ImageFileAttachment(
      name: _patchMap.containsKey(ImageFileAttachment$.name)
          ? (_patchMap[ImageFileAttachment$.name] is Function)
                ? _patchMap[ImageFileAttachment$.name](this.name)
                : (_patchMap[ImageFileAttachment$.name] is Patch)
                ? _patchMap[ImageFileAttachment$.name].applyTo(this.name)
                : _patchMap[ImageFileAttachment$.name]
          : this.name,
      mimeType: _patchMap.containsKey(ImageFileAttachment$.mimeType)
          ? (_patchMap[ImageFileAttachment$.mimeType] is Function)
                ? _patchMap[ImageFileAttachment$.mimeType](this.mimeType)
                : (_patchMap[ImageFileAttachment$.mimeType] is Patch)
                ? _patchMap[ImageFileAttachment$.mimeType].applyTo(
                    this.mimeType,
                  )
                : _patchMap[ImageFileAttachment$.mimeType]
          : this.mimeType,
      bytes: _patchMap.containsKey(ImageFileAttachment$.bytes)
          ? (_patchMap[ImageFileAttachment$.bytes] is Function)
                ? _patchMap[ImageFileAttachment$.bytes](this.bytes)
                : (_patchMap[ImageFileAttachment$.bytes] is Patch)
                ? _patchMap[ImageFileAttachment$.bytes].applyTo(this.bytes)
                : _patchMap[ImageFileAttachment$.bytes]
          : this.bytes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageFileAttachment &&
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
    return 'ImageFileAttachment(' +
        'name: ${name}' +
        ', ' +
        'mimeType: ${mimeType}' +
        ', ' +
        'bytes: ${bytes})';
  }

  /// Creates a [ImageFileAttachment] instance from JSON
  factory ImageFileAttachment.fromJson(Map<String, dynamic> json) =>
      _$ImageFileAttachmentFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ImageFileAttachmentToJson(this);
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
    final json = _$ImageFileAttachmentToJson(this);
    json['__typename'] = 'ImageFileAttachment';
    return json;
  }
}

extension ImageFileAttachmentSerialization on ImageFileAttachment {
  Map<String, dynamic> toJson() => _$ImageFileAttachmentToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ImageFileAttachmentToJson(this);
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
}

enum ImageFileAttachment$ { name, mimeType, bytes }

class ImageFileAttachmentPatch
    extends PatchBase<ImageFileAttachment, ImageFileAttachment$> {
  ImageFileAttachment applyTo(ImageFileAttachment entity) {
    return entity.patchWithImageFileAttachment(patchInput: this);
  }

  ImageFileAttachmentPatch withName(String? value) {
    patchMap[ImageFileAttachment$.name] = value;
    return this;
  }

  ImageFileAttachmentPatch withMimeType(String? value) {
    patchMap[ImageFileAttachment$.mimeType] = value;
    return this;
  }

  ImageFileAttachmentPatch withBytes(List<int>? value) {
    patchMap[ImageFileAttachment$.bytes] = value;
    return this;
  }
}

/// Field descriptors for [ImageFileAttachment] query construction
abstract final class ImageFileAttachmentFields {
  static String _$getname(ImageFileAttachment e) => e.name;
  static const name = Field<ImageFileAttachment, String>('name', _$getname);
  static String _$getmimeType(ImageFileAttachment e) => e.mimeType;
  static const mimeType = Field<ImageFileAttachment, String>(
    'mimeType',
    _$getmimeType,
  );
  static List<int> _$getbytes(ImageFileAttachment e) => e.bytes;
  static const bytes = Field<ImageFileAttachment, List<int>>(
    'bytes',
    _$getbytes,
  );
}

extension ImageFileAttachmentCompareE on ImageFileAttachment {
  Map<String, dynamic> compareToImageFileAttachment(ImageFileAttachment other) {
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
