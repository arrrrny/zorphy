// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'map_field_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class MapHolder {
  final String id;
  final Map<String, String>? replacements;
  final Map<String, int> counts;
  final Map<String, Tag>? tags;

  MapHolder({
    required this.id,
    this.replacements,
    required this.counts,
    this.tags,
  });

  MapHolder copyWith({
    String? id,
    Map<String, String>? replacements,
    Map<String, int>? counts,
    Map<String, Tag>? tags,
  }) {
    return MapHolder(
      id: id ?? this.id,
      replacements: replacements ?? this.replacements,
      counts: counts ?? this.counts,
      tags: tags ?? this.tags,
    );
  }

  MapHolder copyWithMapHolder({
    String? id,
    Map<String, String>? replacements,
    Map<String, int>? counts,
    Map<String, Tag>? tags,
  }) {
    return copyWith(
      id: id,
      replacements: replacements,
      counts: counts,
      tags: tags,
    );
  }

  MapHolder patchWithMapHolder({MapHolderPatch? patchInput}) {
    final _patcher = patchInput ?? MapHolderPatch();
    final _patchMap = _patcher.patchMap;
    return MapHolder(
      id: _patchMap.containsKey(MapHolder$.id)
          ? (_patchMap[MapHolder$.id] is Function)
                ? _patchMap[MapHolder$.id](this.id)
                : (_patchMap[MapHolder$.id] is Patch)
                ? _patchMap[MapHolder$.id].applyTo(this.id)
                : _patchMap[MapHolder$.id]
          : this.id,
      replacements: _patchMap.containsKey(MapHolder$.replacements)
          ? (_patchMap[MapHolder$.replacements] is Function)
                ? _patchMap[MapHolder$.replacements](this.replacements)
                : (_patchMap[MapHolder$.replacements] is Patch)
                ? _patchMap[MapHolder$.replacements].applyTo(this.replacements)
                : _patchMap[MapHolder$.replacements]
          : this.replacements,
      counts: _patchMap.containsKey(MapHolder$.counts)
          ? (_patchMap[MapHolder$.counts] is Function)
                ? _patchMap[MapHolder$.counts](this.counts)
                : (_patchMap[MapHolder$.counts] is Patch)
                ? _patchMap[MapHolder$.counts].applyTo(this.counts)
                : _patchMap[MapHolder$.counts]
          : this.counts,
      tags: _patchMap.containsKey(MapHolder$.tags)
          ? (_patchMap[MapHolder$.tags] is Function)
                ? _patchMap[MapHolder$.tags](this.tags)
                : (_patchMap[MapHolder$.tags] is Patch)
                ? _patchMap[MapHolder$.tags].applyTo(this.tags)
                : _patchMap[MapHolder$.tags]
          : this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapHolder &&
        id == other.id &&
        replacements == other.replacements &&
        counts == other.counts &&
        tags == other.tags;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.replacements, this.counts, this.tags);
  }

  @override
  String toString() {
    return 'MapHolder(' +
        'id: ${id}' +
        ', ' +
        'replacements: ${replacements}' +
        ', ' +
        'counts: ${counts}' +
        ', ' +
        'tags: ${tags})';
  }

  /// Creates a [MapHolder] instance from JSON
  factory MapHolder.fromJson(Map<String, dynamic> json) =>
      _$MapHolderFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$MapHolderToJson(this);
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

extension MapHolderPropertyHelpers on MapHolder {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  Map<String, String> get replacementsRequired =>
      replacements ??
      (throw StateError('replacements is required but was null'));
  bool get hasReplacements => replacements?.isNotEmpty ?? false;
  bool get noReplacements => replacements?.isEmpty ?? true;
  bool get hasCounts => counts.isNotEmpty;
  bool get noCounts => counts.isEmpty;
  Map<String, Tag> get tagsRequired =>
      tags ?? (throw StateError('tags is required but was null'));
  bool get hasTags => tags?.isNotEmpty ?? false;
  bool get noTags => tags?.isEmpty ?? true;
}

extension MapHolderSerialization on MapHolder {
  Map<String, dynamic> toJson() => _$MapHolderToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$MapHolderToJson(this);
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

enum MapHolder$ { id, replacements, counts, tags }

class MapHolderPatch extends PatchBase<MapHolder, MapHolder$> {
  MapHolder applyTo(MapHolder entity) {
    return entity.patchWithMapHolder(patchInput: this);
  }

  MapHolderPatch withId(String? value) {
    patchMap[MapHolder$.id] = value;
    return this;
  }

  MapHolderPatch withReplacements(Map<String, String>? value) {
    patchMap[MapHolder$.replacements] = value;
    return this;
  }

  MapHolderPatch withCounts(Map<String, int>? value) {
    patchMap[MapHolder$.counts] = value;
    return this;
  }

  MapHolderPatch withTags(Map<String, Tag>? value) {
    patchMap[MapHolder$.tags] = value;
    return this;
  }
}

/// Field descriptors for [MapHolder] query construction
abstract final class MapHolderFields {
  static String _$getid(MapHolder e) => e.id;
  static const id = Field<MapHolder, String>('id', _$getid);
  static Map<String, String>? _$getreplacements(MapHolder e) => e.replacements;
  static const replacements = Field<MapHolder, Map<String, String>?>(
    'replacements',
    _$getreplacements,
  );
  static Map<String, int> _$getcounts(MapHolder e) => e.counts;
  static const counts = Field<MapHolder, Map<String, int>>(
    'counts',
    _$getcounts,
  );
  static Map<String, Tag>? _$gettags(MapHolder e) => e.tags;
  static const tags = Field<MapHolder, Map<String, Tag>?>('tags', _$gettags);
}

extension MapHolderCompareE on MapHolder {
  Map<String, dynamic> compareToMapHolder(MapHolder other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (replacements != other.replacements) {
      diff['replacements'] = () => other.replacements;
    }
    if (counts != other.counts) {
      diff['counts'] = () => other.counts;
    }
    if (tags != other.tags) {
      diff['tags'] = () => other.tags;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Tag {
  final String label;

  Tag({required this.label});

  Tag copyWith({String? label}) {
    return Tag(label: label ?? this.label);
  }

  Tag copyWithTag({String? label}) {
    return copyWith(label: label);
  }

  Tag patchWithTag({TagPatch? patchInput}) {
    final _patcher = patchInput ?? TagPatch();
    final _patchMap = _patcher.patchMap;
    return Tag(
      label: _patchMap.containsKey(Tag$.label)
          ? (_patchMap[Tag$.label] is Function)
                ? _patchMap[Tag$.label](this.label)
                : (_patchMap[Tag$.label] is Patch)
                ? _patchMap[Tag$.label].applyTo(this.label)
                : _patchMap[Tag$.label]
          : this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && label == other.label;
  }

  @override
  int get hashCode {
    return Object.hash(label, 0);
  }

  @override
  String toString() {
    return 'Tag(' + 'label: ${label})';
  }

  /// Creates a [Tag] instance from JSON
  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TagToJson(this);
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

extension TagPropertyHelpers on Tag {
  bool get hasLabel => label.isNotEmpty;
  bool get noLabel => label.isEmpty;
}

extension TagSerialization on Tag {
  Map<String, dynamic> toJson() => _$TagToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TagToJson(this);
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

enum Tag$ { label }

class TagPatch extends PatchBase<Tag, Tag$> {
  Tag applyTo(Tag entity) {
    return entity.patchWithTag(patchInput: this);
  }

  TagPatch withLabel(String? value) {
    patchMap[Tag$.label] = value;
    return this;
  }
}

/// Field descriptors for [Tag] query construction
abstract final class TagFields {
  static String _$getlabel(Tag e) => e.label;
  static const label = Field<Tag, String>('label', _$getlabel);
}

extension TagCompareE on Tag {
  Map<String, dynamic> compareToTag(Tag other) {
    final Map<String, dynamic> diff = {};

    if (label != other.label) {
      diff['label'] = () => other.label;
    }
    return diff;
  }
}
