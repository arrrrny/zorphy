// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'attachment.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

abstract class Attachment {
  String get name;
  String get mimeType;
  List<int> get bytes;

  Attachment();

  /// Creates a [Attachment] instance from JSON
  factory Attachment.fromJson(Map<String, dynamic> json) {
    if (json['__typename'] == "FileAttachment") {
      return FileAttachment.fromJson(json);
    } else if (json['__typename'] == "LinkAttachment") {
      return LinkAttachment.fromJson(json);
    }
    throw UnsupportedError(
      "The __typename ' + ${json['__typename']}' is not supported by the Attachment.fromJson constructor.",
    );
  }

  Map<String, dynamic> toJson() {
    if (this is FileAttachment) {
      final json = (this as FileAttachment).toJsonLean();
      json['__typename'] = "FileAttachment";
      return json;
    } else if (this is LinkAttachment) {
      final json = (this as LinkAttachment).toJsonLean();
      json['__typename'] = "LinkAttachment";
      return json;
    }
    throw UnsupportedError("Unknown subtype: $runtimeType");
  }
}

extension AttachmentPolymorphicE on Attachment {
  bool get isFileAttachment => this is FileAttachment;
  FileAttachment? get asFileAttachment =>
      this is FileAttachment ? this as FileAttachment : null;
  bool get isLinkAttachment => this is LinkAttachment;
  LinkAttachment? get asLinkAttachment =>
      this is LinkAttachment ? this as LinkAttachment : null;
}

extension AttachmentPropertyHelpers on Attachment {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasMimeType => mimeType.isNotEmpty;
  bool get noMimeType => mimeType.isEmpty;
  bool get hasBytes => bytes.isNotEmpty;
  bool get noBytes => bytes.isEmpty;
}

enum Attachment$ { name, mimeType, bytes }

/// Field descriptors for [Attachment] query construction
abstract final class AttachmentFields {
  static String _$getname(Attachment e) => e.name;
  static const name = Field<Attachment, String>('name', _$getname);
  static String _$getmimeType(Attachment e) => e.mimeType;
  static const mimeType = Field<Attachment, String>('mimeType', _$getmimeType);
  static List<int> _$getbytes(Attachment e) => e.bytes;
  static const bytes = Field<Attachment, List<int>>('bytes', _$getbytes);
}

extension AttachmentCompareE on Attachment {
  Map<String, dynamic> compareToAttachment(Attachment other) {
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

extension AttachmentChangeToE on Attachment {
  FileAttachment changeToFileAttachment({
    String? name,
    String? mimeType,
    List<int>? bytes,
  }) {
    final _patcher = FileAttachmentPatch();
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
    return FileAttachment.fromJson(_json);
  }

  LinkAttachment changeToLinkAttachment({
    required String url,
    String? name,
    String? mimeType,
    List<int>? bytes,
  }) {
    final _patcher = LinkAttachmentPatch();
    _patcher.withUrl(url);
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
    return LinkAttachment.fromJson(_json);
  }
}
