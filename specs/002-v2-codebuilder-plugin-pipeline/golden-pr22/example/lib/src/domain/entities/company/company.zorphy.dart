// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'company.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Company {
  final String name;
  final List<User> employees;
  final List<String> locations;

  Company({
    required this.name,
    required this.employees,
    required this.locations,
  });

  Company copyWith({
    String? name,
    List<User>? employees,
    List<String>? locations,
  }) {
    return Company(
      name: name ?? this.name,
      employees: employees ?? this.employees,
      locations: locations ?? this.locations,
    );
  }

  Company copyWithCompany({
    String? name,
    List<User>? employees,
    List<String>? locations,
  }) {
    return copyWith(name: name, employees: employees, locations: locations);
  }

  Company patchWithCompany({CompanyPatch? patchInput}) {
    final _patcher = patchInput ?? CompanyPatch();
    final _patchMap = _patcher.patchMap;
    return Company(
      name: _patchMap.containsKey(Company$.name)
          ? (_patchMap[Company$.name] is Function)
                ? _patchMap[Company$.name](this.name)
                : (_patchMap[Company$.name] is Patch)
                ? _patchMap[Company$.name].applyTo(this.name)
                : _patchMap[Company$.name]
          : this.name,
      employees: _patchMap.containsKey(Company$.employees)
          ? (_patchMap[Company$.employees] is Function)
                ? _patchMap[Company$.employees](this.employees)
                : (_patchMap[Company$.employees] is Patch)
                ? _patchMap[Company$.employees].applyTo(this.employees)
                : _patchMap[Company$.employees]
          : this.employees,
      locations: _patchMap.containsKey(Company$.locations)
          ? (_patchMap[Company$.locations] is Function)
                ? _patchMap[Company$.locations](this.locations)
                : (_patchMap[Company$.locations] is Patch)
                ? _patchMap[Company$.locations].applyTo(this.locations)
                : _patchMap[Company$.locations]
          : this.locations,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        name == other.name &&
        employees == other.employees &&
        locations == other.locations;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.employees, this.locations);
  }

  @override
  String toString() {
    return 'Company(' +
        'name: ${name}' +
        ', ' +
        'employees: ${employees}' +
        ', ' +
        'locations: ${locations})';
  }

  /// Creates a [Company] instance from JSON
  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CompanyToJson(this);
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

extension CompanyPropertyHelpers on Company {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasEmployees => employees.isNotEmpty;
  bool get noEmployees => employees.isEmpty;
  bool get hasLocations => locations.isNotEmpty;
  bool get noLocations => locations.isEmpty;
}

extension CompanySerialization on Company {
  Map<String, dynamic> toJson() => _$CompanyToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CompanyToJson(this);
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

enum Company$ { name, employees, locations }

class CompanyPatch extends PatchBase<Company, Company$> {
  Company applyTo(Company entity) {
    return entity.patchWithCompany(patchInput: this);
  }

  CompanyPatch withName(String? value) {
    patchMap[Company$.name] = value;
    return this;
  }

  CompanyPatch withEmployees(List<User>? value) {
    patchMap[Company$.employees] = value;
    return this;
  }

  CompanyPatch updateEmployeesAt(
    int index,
    UserPatch Function(UserPatch) patch,
  ) {
    patchMap[Company$.employees] = (List<dynamic> list) {
      var updatedList = List.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(
          UserPatch(),
        ).applyTo(updatedList[index] as User);
      }
      return updatedList;
    };
    return this;
  }

  CompanyPatch withLocations(List<String>? value) {
    patchMap[Company$.locations] = value;
    return this;
  }
}

/// Field descriptors for [Company] query construction
abstract final class CompanyFields {
  static String _$getname(Company e) => e.name;
  static const name = Field<Company, String>('name', _$getname);
  static List<User> _$getemployees(Company e) => e.employees;
  static const employees = Field<Company, List<User>>(
    'employees',
    _$getemployees,
  );
  static List<String> _$getlocations(Company e) => e.locations;
  static const locations = Field<Company, List<String>>(
    'locations',
    _$getlocations,
  );
}

extension CompanyCompareE on Company {
  Map<String, dynamic> compareToCompany(Company other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (employees != other.employees) {
      diff['employees'] = () => other.employees;
    }
    if (locations != other.locations) {
      diff['locations'] = () => other.locations;
    }
    return diff;
  }
}
