// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'demographics.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Demographics extends $Demographics {
  @override
  final AgeGroup? ageGroup;
  @override
  final Generation? generation;
  @override
  final List<String>? locations;
  @override
  final IncomeLevel? incomeLevel;
  @override
  final List<String>? lifestyle;

  Demographics({
    this.ageGroup,
    this.generation,
    this.locations,
    this.incomeLevel,
    this.lifestyle,
  });

  Demographics copyWith({
    AgeGroup? ageGroup,
    Generation? generation,
    List<String>? locations,
    IncomeLevel? incomeLevel,
    List<String>? lifestyle,
  }) {
    return Demographics(
      ageGroup: ageGroup ?? this.ageGroup,
      generation: generation ?? this.generation,
      locations: locations ?? this.locations,
      incomeLevel: incomeLevel ?? this.incomeLevel,
      lifestyle: lifestyle ?? this.lifestyle,
    );
  }

  Demographics copyWithDemographics({
    AgeGroup? ageGroup,
    Generation? generation,
    List<String>? locations,
    IncomeLevel? incomeLevel,
    List<String>? lifestyle,
  }) {
    return copyWith(
      ageGroup: ageGroup,
      generation: generation,
      locations: locations,
      incomeLevel: incomeLevel,
      lifestyle: lifestyle,
    );
  }

  Demographics patchWithDemographics({
    DemographicsPatch? patchInput,
  }) {
    final _patcher = patchInput ?? DemographicsPatch();
    final _patchMap = _patcher.toPatch();
    return Demographics(
        ageGroup: _patchMap.containsKey(Demographics$.ageGroup)
            ? (_patchMap[Demographics$.ageGroup] is Function)
                ? _patchMap[Demographics$.ageGroup](this.ageGroup)
                : _patchMap[Demographics$.ageGroup]
            : this.ageGroup,
        generation: _patchMap.containsKey(Demographics$.generation)
            ? (_patchMap[Demographics$.generation] is Function)
                ? _patchMap[Demographics$.generation](this.generation)
                : _patchMap[Demographics$.generation]
            : this.generation,
        locations: _patchMap.containsKey(Demographics$.locations)
            ? (_patchMap[Demographics$.locations] is Function)
                ? _patchMap[Demographics$.locations](this.locations)
                : _patchMap[Demographics$.locations]
            : this.locations,
        incomeLevel: _patchMap.containsKey(Demographics$.incomeLevel)
            ? (_patchMap[Demographics$.incomeLevel] is Function)
                ? _patchMap[Demographics$.incomeLevel](this.incomeLevel)
                : _patchMap[Demographics$.incomeLevel]
            : this.incomeLevel,
        lifestyle: _patchMap.containsKey(Demographics$.lifestyle)
            ? (_patchMap[Demographics$.lifestyle] is Function)
                ? _patchMap[Demographics$.lifestyle](this.lifestyle)
                : _patchMap[Demographics$.lifestyle]
            : this.lifestyle);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Demographics &&
        ageGroup == other.ageGroup &&
        generation == other.generation &&
        locations == other.locations &&
        incomeLevel == other.incomeLevel &&
        lifestyle == other.lifestyle;
  }

  @override
  int get hashCode {
    return Object.hash(this.ageGroup, this.generation, this.locations,
        this.incomeLevel, this.lifestyle);
  }

  @override
  String toString() {
    return 'Demographics(' +
        'ageGroup: ${ageGroup}' +
        ', ' +
        'generation: ${generation}' +
        ', ' +
        'locations: ${locations}' +
        ', ' +
        'incomeLevel: ${incomeLevel}' +
        ', ' +
        'lifestyle: ${lifestyle})';
  }

  /// Creates a [Demographics] instance from JSON
  factory Demographics.fromJson(Map<String, dynamic> json) =>
      _$DemographicsFromJson(json);
}

enum Demographics$ { ageGroup, generation, locations, incomeLevel, lifestyle }

class DemographicsPatch implements Patch<Demographics> {
  final Map<Demographics$, dynamic> _patch = {};

  static DemographicsPatch create([Map<String, dynamic>? diff]) {
    final patch = DemographicsPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue =
              Demographics$.values.firstWhere((e) => e.name == key);
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

  static DemographicsPatch fromPatch(Map<Demographics$, dynamic> patch) {
    final _patch = DemographicsPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Demographics$, dynamic> toPatch() => Map.from(_patch);

  Demographics applyTo(Demographics entity) {
    return entity.patchWithDemographics(patchInput: this);
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

  static DemographicsPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  DemographicsPatch withAgeGroup(AgeGroup? value) {
    _patch[Demographics$.ageGroup] = value;
    return this;
  }

  DemographicsPatch withGeneration(Generation? value) {
    _patch[Demographics$.generation] = value;
    return this;
  }

  DemographicsPatch withLocations(List<String>? value) {
    _patch[Demographics$.locations] = value;
    return this;
  }

  DemographicsPatch withIncomeLevel(IncomeLevel? value) {
    _patch[Demographics$.incomeLevel] = value;
    return this;
  }

  DemographicsPatch withLifestyle(List<String>? value) {
    _patch[Demographics$.lifestyle] = value;
    return this;
  }
}

extension DemographicsSerialization on Demographics {
  Map<String, dynamic> toJson() => _$DemographicsToJson(this);
}

extension DemographicsCompareE on Demographics {
  Map<String, dynamic> compareToDemographics(Demographics other) {
    final Map<String, dynamic> diff = {};

    if (ageGroup != other.ageGroup) {
      diff['ageGroup'] = () => other.ageGroup;
    }
    if (generation != other.generation) {
      diff['generation'] = () => other.generation;
    }
    if (locations != other.locations) {
      diff['locations'] = () => other.locations;
    }
    if (incomeLevel != other.incomeLevel) {
      diff['incomeLevel'] = () => other.incomeLevel;
    }
    if (lifestyle != other.lifestyle) {
      diff['lifestyle'] = () => other.lifestyle;
    }
    return diff;
  }
}
