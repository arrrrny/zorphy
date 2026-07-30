// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'link_attachment.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class LinkAttachment extends Attachment {
  @override
  final String name;
  @override
  final String mimeType;
  @override
  final List<int> bytes;
  final String url;

  LinkAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
    required this.url,
  }) : super();

  LinkAttachment copyWith({
    String? name,
    String? mimeType,
    List<int>? bytes,
    String? url,
  }) {
    return LinkAttachment(
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      bytes: bytes ?? this.bytes,
      url: url ?? this.url,
    );
  }

  LinkAttachment copyWithLinkAttachment({
    String? name,
    String? mimeType,
    List<int>? bytes,
    String? url,
  }) {
    return copyWith(name: name, mimeType: mimeType, bytes: bytes, url: url);
  }

  LinkAttachment patchWithLinkAttachment({LinkAttachmentPatch? patchInput}) {
    final _patcher = patchInput ?? LinkAttachmentPatch();
    final _patchMap = _patcher.patchMap;
    return LinkAttachment(
      name: _patchMap.containsKey(LinkAttachment$.name)
          ? (_patchMap[LinkAttachment$.name] is Function)
                ? _patchMap[LinkAttachment$.name](this.name)
                : (_patchMap[LinkAttachment$.name] is Patch)
                ? _patchMap[LinkAttachment$.name].applyTo(this.name)
                : _patchMap[LinkAttachment$.name]
          : this.name,
      mimeType: _patchMap.containsKey(LinkAttachment$.mimeType)
          ? (_patchMap[LinkAttachment$.mimeType] is Function)
                ? _patchMap[LinkAttachment$.mimeType](this.mimeType)
                : (_patchMap[LinkAttachment$.mimeType] is Patch)
                ? _patchMap[LinkAttachment$.mimeType].applyTo(this.mimeType)
                : _patchMap[LinkAttachment$.mimeType]
          : this.mimeType,
      bytes: _patchMap.containsKey(LinkAttachment$.bytes)
          ? (_patchMap[LinkAttachment$.bytes] is Function)
                ? _patchMap[LinkAttachment$.bytes](this.bytes)
                : (_patchMap[LinkAttachment$.bytes] is Patch)
                ? _patchMap[LinkAttachment$.bytes].applyTo(this.bytes)
                : _patchMap[LinkAttachment$.bytes]
          : this.bytes,
      url: _patchMap.containsKey(LinkAttachment$.url)
          ? (_patchMap[LinkAttachment$.url] is Function)
                ? _patchMap[LinkAttachment$.url](this.url)
                : (_patchMap[LinkAttachment$.url] is Patch)
                ? _patchMap[LinkAttachment$.url].applyTo(this.url)
                : _patchMap[LinkAttachment$.url]
          : this.url,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkAttachment &&
        name == other.name &&
        mimeType == other.mimeType &&
        bytes == other.bytes &&
        url == other.url;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.mimeType, this.bytes, this.url);
  }

  @override
  String toString() {
    return 'LinkAttachment(' +
        'name: ${name}' +
        ', ' +
        'mimeType: ${mimeType}' +
        ', ' +
        'bytes: ${bytes}' +
        ', ' +
        'url: ${url})';
  }

  /// Creates a [LinkAttachment] instance from JSON
  factory LinkAttachment.fromJson(Map<String, dynamic> json) =>
      _$LinkAttachmentFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$LinkAttachmentToJson(this);
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
    final json = _$LinkAttachmentToJson(this);
    json['__typename'] = 'LinkAttachment';
    return json;
  }
}

extension LinkAttachmentPropertyHelpers on LinkAttachment {
  bool get hasUrl => url.isNotEmpty;
  bool get noUrl => url.isEmpty;
}

extension LinkAttachmentSerialization on LinkAttachment {
  Map<String, dynamic> toJson() => _$LinkAttachmentToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$LinkAttachmentToJson(this);
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

enum LinkAttachment$ { name, mimeType, bytes, url }

class LinkAttachmentPatch extends PatchBase<LinkAttachment, LinkAttachment$> {
  LinkAttachment applyTo(LinkAttachment entity) {
    return entity.patchWithLinkAttachment(patchInput: this);
  }

  LinkAttachmentPatch withName(String? value) {
    patchMap[LinkAttachment$.name] = value;
    return this;
  }

  LinkAttachmentPatch withMimeType(String? value) {
    patchMap[LinkAttachment$.mimeType] = value;
    return this;
  }

  LinkAttachmentPatch withBytes(List<int>? value) {
    patchMap[LinkAttachment$.bytes] = value;
    return this;
  }

  LinkAttachmentPatch withUrl(String? value) {
    patchMap[LinkAttachment$.url] = value;
    return this;
  }
}

/// Field descriptors for [LinkAttachment] query construction
abstract final class LinkAttachmentFields {
  static String _$getname(LinkAttachment e) => e.name;
  static const name = Field<LinkAttachment, String>('name', _$getname);
  static String _$getmimeType(LinkAttachment e) => e.mimeType;
  static const mimeType = Field<LinkAttachment, String>(
    'mimeType',
    _$getmimeType,
  );
  static List<int> _$getbytes(LinkAttachment e) => e.bytes;
  static const bytes = Field<LinkAttachment, List<int>>('bytes', _$getbytes);
  static String _$geturl(LinkAttachment e) => e.url;
  static const url = Field<LinkAttachment, String>('url', _$geturl);
}

extension LinkAttachmentCompareE on LinkAttachment {
  Map<String, dynamic> compareToLinkAttachment(LinkAttachment other) {
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
    if (url != other.url) {
      diff['url'] = () => other.url;
    }
    return diff;
  }
}
