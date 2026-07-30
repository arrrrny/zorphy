// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'nested_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  Address copyWith({
    String? street,
    String? city,
    String? state,
    String? zipCode,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
    );
  }

  Address copyWithAddress({
    String? street,
    String? city,
    String? state,
    String? zipCode,
  }) {
    return copyWith(street: street, city: city, state: state, zipCode: zipCode);
  }

  Address patchWithAddress({AddressPatch? patchInput}) {
    final _patcher = patchInput ?? AddressPatch();
    final _patchMap = _patcher.patchMap;
    return Address(
      street: _patchMap.containsKey(Address$.street)
          ? (_patchMap[Address$.street] is Function)
                ? _patchMap[Address$.street](this.street)
                : (_patchMap[Address$.street] is Patch)
                ? _patchMap[Address$.street].applyTo(this.street)
                : _patchMap[Address$.street]
          : this.street,
      city: _patchMap.containsKey(Address$.city)
          ? (_patchMap[Address$.city] is Function)
                ? _patchMap[Address$.city](this.city)
                : (_patchMap[Address$.city] is Patch)
                ? _patchMap[Address$.city].applyTo(this.city)
                : _patchMap[Address$.city]
          : this.city,
      state: _patchMap.containsKey(Address$.state)
          ? (_patchMap[Address$.state] is Function)
                ? _patchMap[Address$.state](this.state)
                : (_patchMap[Address$.state] is Patch)
                ? _patchMap[Address$.state].applyTo(this.state)
                : _patchMap[Address$.state]
          : this.state,
      zipCode: _patchMap.containsKey(Address$.zipCode)
          ? (_patchMap[Address$.zipCode] is Function)
                ? _patchMap[Address$.zipCode](this.zipCode)
                : (_patchMap[Address$.zipCode] is Patch)
                ? _patchMap[Address$.zipCode].applyTo(this.zipCode)
                : _patchMap[Address$.zipCode]
          : this.zipCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        street == other.street &&
        city == other.city &&
        state == other.state &&
        zipCode == other.zipCode;
  }

  @override
  int get hashCode {
    return Object.hash(this.street, this.city, this.state, this.zipCode);
  }

  @override
  String toString() {
    return 'Address(' +
        'street: ${street}' +
        ', ' +
        'city: ${city}' +
        ', ' +
        'state: ${state}' +
        ', ' +
        'zipCode: ${zipCode})';
  }
}

extension AddressPropertyHelpers on Address {
  bool get hasStreet => street.isNotEmpty;
  bool get noStreet => street.isEmpty;
  bool get hasCity => city.isNotEmpty;
  bool get noCity => city.isEmpty;
  bool get hasState => state.isNotEmpty;
  bool get noState => state.isEmpty;
  bool get hasZipCode => zipCode.isNotEmpty;
  bool get noZipCode => zipCode.isEmpty;
}

enum Address$ { street, city, state, zipCode }

class AddressPatch extends PatchBase<Address, Address$> {
  Address applyTo(Address entity) {
    return entity.patchWithAddress(patchInput: this);
  }

  AddressPatch withStreet(String? value) {
    patchMap[Address$.street] = value;
    return this;
  }

  AddressPatch withCity(String? value) {
    patchMap[Address$.city] = value;
    return this;
  }

  AddressPatch withState(String? value) {
    patchMap[Address$.state] = value;
    return this;
  }

  AddressPatch withZipCode(String? value) {
    patchMap[Address$.zipCode] = value;
    return this;
  }
}

extension AddressCompareE on Address {
  Map<String, dynamic> compareToAddress(Address other) {
    final Map<String, dynamic> diff = {};

    if (street != other.street) {
      diff['street'] = () => other.street;
    }
    if (city != other.city) {
      diff['city'] = () => other.city;
    }
    if (state != other.state) {
      diff['state'] = () => other.state;
    }
    if (zipCode != other.zipCode) {
      diff['zipCode'] = () => other.zipCode;
    }
    return diff;
  }
}

class Person {
  final String name;
  final int age;
  final Address address;

  Person({required this.name, required this.age, required this.address});

  Person copyWith({String? name, int? age, Address? address}) {
    return Person(
      name: name ?? this.name,
      age: age ?? this.age,
      address: address ?? this.address,
    );
  }

  Person copyWithPerson({String? name, int? age, Address? address}) {
    return copyWith(name: name, age: age, address: address);
  }

  Person patchWithPerson({PersonPatch? patchInput}) {
    final _patcher = patchInput ?? PersonPatch();
    final _patchMap = _patcher.patchMap;
    return Person(
      name: _patchMap.containsKey(Person$.name)
          ? (_patchMap[Person$.name] is Function)
                ? _patchMap[Person$.name](this.name)
                : (_patchMap[Person$.name] is Patch)
                ? _patchMap[Person$.name].applyTo(this.name)
                : _patchMap[Person$.name]
          : this.name,
      age: _patchMap.containsKey(Person$.age)
          ? (_patchMap[Person$.age] is Function)
                ? _patchMap[Person$.age](this.age)
                : (_patchMap[Person$.age] is Patch)
                ? _patchMap[Person$.age].applyTo(this.age)
                : _patchMap[Person$.age]
          : this.age,
      address: _patchMap.containsKey(Person$.address)
          ? (_patchMap[Person$.address] is Function)
                ? _patchMap[Person$.address](this.address)
                : (_patchMap[Person$.address] is Patch)
                ? _patchMap[Person$.address].applyTo(this.address)
                : _patchMap[Person$.address]
          : this.address,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person &&
        name == other.name &&
        age == other.age &&
        address == other.address;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.age, this.address);
  }

  @override
  String toString() {
    return 'Person(' +
        'name: ${name}' +
        ', ' +
        'age: ${age}' +
        ', ' +
        'address: ${address})';
  }
}

extension PersonPropertyHelpers on Person {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

enum Person$ { name, age, address }

class PersonPatch extends PatchBase<Person, Person$> {
  Person applyTo(Person entity) {
    return entity.patchWithPerson(patchInput: this);
  }

  PersonPatch withName(String? value) {
    patchMap[Person$.name] = value;
    return this;
  }

  PersonPatch withAge(int? value) {
    patchMap[Person$.age] = value;
    return this;
  }

  PersonPatch withAddress(Address? value) {
    patchMap[Person$.address] = value;
    return this;
  }

  PersonPatch withAddressPatch(AddressPatch patch) {
    patchMap[Person$.address] = patch;
    return this;
  }

  PersonPatch withAddressPatchFunc(AddressPatch Function(AddressPatch) patch) {
    patchMap[Person$.address] = (dynamic current) {
      var currentPatch = AddressPatch();
      return patch(currentPatch).applyTo(current as Address);
    };
    return this;
  }
}

extension PersonCompareE on Person {
  Map<String, dynamic> compareToPerson(Person other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (address != other.address) {
      diff['address'] = () => other.address;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class CategoryNode {
  final String id;
  final String name;
  final List<CategoryNode>? children;
  final CategoryNode? parent;

  CategoryNode({
    required this.id,
    required this.name,
    this.children,
    this.parent,
  });

  CategoryNode copyWith({
    String? id,
    String? name,
    List<CategoryNode>? children,
    CategoryNode? parent,
  }) {
    return CategoryNode(
      id: id ?? this.id,
      name: name ?? this.name,
      children: children ?? this.children,
      parent: parent ?? this.parent,
    );
  }

  CategoryNode copyWithCategoryNode({
    String? id,
    String? name,
    List<CategoryNode>? children,
    CategoryNode? parent,
  }) {
    return copyWith(id: id, name: name, children: children, parent: parent);
  }

  CategoryNode patchWithCategoryNode({CategoryNodePatch? patchInput}) {
    final _patcher = patchInput ?? CategoryNodePatch();
    final _patchMap = _patcher.patchMap;
    return CategoryNode(
      id: _patchMap.containsKey(CategoryNode$.id)
          ? (_patchMap[CategoryNode$.id] is Function)
                ? _patchMap[CategoryNode$.id](this.id)
                : (_patchMap[CategoryNode$.id] is Patch)
                ? _patchMap[CategoryNode$.id].applyTo(this.id)
                : _patchMap[CategoryNode$.id]
          : this.id,
      name: _patchMap.containsKey(CategoryNode$.name)
          ? (_patchMap[CategoryNode$.name] is Function)
                ? _patchMap[CategoryNode$.name](this.name)
                : (_patchMap[CategoryNode$.name] is Patch)
                ? _patchMap[CategoryNode$.name].applyTo(this.name)
                : _patchMap[CategoryNode$.name]
          : this.name,
      children: _patchMap.containsKey(CategoryNode$.children)
          ? (_patchMap[CategoryNode$.children] is Function)
                ? _patchMap[CategoryNode$.children](this.children)
                : (_patchMap[CategoryNode$.children] is Patch)
                ? _patchMap[CategoryNode$.children].applyTo(this.children)
                : _patchMap[CategoryNode$.children]
          : this.children,
      parent: _patchMap.containsKey(CategoryNode$.parent)
          ? (_patchMap[CategoryNode$.parent] is Function)
                ? _patchMap[CategoryNode$.parent](this.parent)
                : (_patchMap[CategoryNode$.parent] is Patch)
                ? _patchMap[CategoryNode$.parent].applyTo(this.parent)
                : _patchMap[CategoryNode$.parent]
          : this.parent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryNode &&
        id == other.id &&
        name == other.name &&
        children == other.children &&
        parent == other.parent;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.children, this.parent);
  }

  @override
  String toString() {
    return 'CategoryNode(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'children: ${children}' +
        ', ' +
        'parent: ${parent})';
  }

  /// Creates a [CategoryNode] instance from JSON
  factory CategoryNode.fromJson(Map<String, dynamic> json) =>
      _$CategoryNodeFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CategoryNodeToJson(this);
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

extension CategoryNodePropertyHelpers on CategoryNode {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  List<CategoryNode> get childrenRequired =>
      children ?? (throw StateError('children is required but was null'));
  bool get hasChildren => children?.isNotEmpty ?? false;
  bool get noChildren => children?.isEmpty ?? true;
  bool get hasParent => parent != null;
  bool get noParent => parent == null;
  CategoryNode get parentRequired =>
      parent ?? (throw StateError('parent is required but was null'));
}

extension CategoryNodeSerialization on CategoryNode {
  Map<String, dynamic> toJson() => _$CategoryNodeToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CategoryNodeToJson(this);
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

enum CategoryNode$ { id, name, children, parent }

class CategoryNodePatch extends PatchBase<CategoryNode, CategoryNode$> {
  CategoryNode applyTo(CategoryNode entity) {
    return entity.patchWithCategoryNode(patchInput: this);
  }

  CategoryNodePatch withId(String? value) {
    patchMap[CategoryNode$.id] = value;
    return this;
  }

  CategoryNodePatch withName(String? value) {
    patchMap[CategoryNode$.name] = value;
    return this;
  }

  CategoryNodePatch withChildren(List<CategoryNode>? value) {
    patchMap[CategoryNode$.children] = value;
    return this;
  }

  CategoryNodePatch updateChildrenAt(
    int index,
    CategoryNodePatch Function(CategoryNodePatch) patch,
  ) {
    patchMap[CategoryNode$.children] = (List<dynamic> list) {
      var updatedList = List.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(
          CategoryNodePatch(),
        ).applyTo(updatedList[index] as CategoryNode);
      }
      return updatedList;
    };
    return this;
  }

  CategoryNodePatch withParent(CategoryNode? value) {
    patchMap[CategoryNode$.parent] = value;
    return this;
  }

  CategoryNodePatch withParentPatch(CategoryNodePatch patch) {
    patchMap[CategoryNode$.parent] = patch;
    return this;
  }

  CategoryNodePatch withParentPatchFunc(
    CategoryNodePatch Function(CategoryNodePatch) patch,
  ) {
    patchMap[CategoryNode$.parent] = (dynamic current) {
      var currentPatch = CategoryNodePatch();
      return patch(currentPatch).applyTo(current as CategoryNode);
    };
    return this;
  }
}

/// Field descriptors for [CategoryNode] query construction
abstract final class CategoryNodeFields {
  static String _$getid(CategoryNode e) => e.id;
  static const id = Field<CategoryNode, String>('id', _$getid);
  static String _$getname(CategoryNode e) => e.name;
  static const name = Field<CategoryNode, String>('name', _$getname);
  static List<CategoryNode>? _$getchildren(CategoryNode e) => e.children;
  static const children = Field<CategoryNode, List<CategoryNode>?>(
    'children',
    _$getchildren,
  );
  static CategoryNode? _$getparent(CategoryNode e) => e.parent;
  static const parent = Field<CategoryNode, CategoryNode?>(
    'parent',
    _$getparent,
  );
}

extension CategoryNodeCompareE on CategoryNode {
  Map<String, dynamic> compareToCategoryNode(CategoryNode other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (children != other.children) {
      diff['children'] = () => other.children;
    }
    if (parent != other.parent) {
      diff['parent'] = () => other.parent;
    }
    return diff;
  }
}

class Company {
  final String name;
  final Address headquarters;
  final List<Department>? departments;

  Company({required this.name, required this.headquarters, this.departments});

  Company copyWith({
    String? name,
    Address? headquarters,
    List<Department>? departments,
  }) {
    return Company(
      name: name ?? this.name,
      headquarters: headquarters ?? this.headquarters,
      departments: departments ?? this.departments,
    );
  }

  Company copyWithCompany({
    String? name,
    Address? headquarters,
    List<Department>? departments,
  }) {
    return copyWith(
      name: name,
      headquarters: headquarters,
      departments: departments,
    );
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
      headquarters: _patchMap.containsKey(Company$.headquarters)
          ? (_patchMap[Company$.headquarters] is Function)
                ? _patchMap[Company$.headquarters](this.headquarters)
                : (_patchMap[Company$.headquarters] is Patch)
                ? _patchMap[Company$.headquarters].applyTo(this.headquarters)
                : _patchMap[Company$.headquarters]
          : this.headquarters,
      departments: _patchMap.containsKey(Company$.departments)
          ? (_patchMap[Company$.departments] is Function)
                ? _patchMap[Company$.departments](this.departments)
                : (_patchMap[Company$.departments] is Patch)
                ? _patchMap[Company$.departments].applyTo(this.departments)
                : _patchMap[Company$.departments]
          : this.departments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        name == other.name &&
        headquarters == other.headquarters &&
        departments == other.departments;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.headquarters, this.departments);
  }

  @override
  String toString() {
    return 'Company(' +
        'name: ${name}' +
        ', ' +
        'headquarters: ${headquarters}' +
        ', ' +
        'departments: ${departments})';
  }
}

extension CompanyPropertyHelpers on Company {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  List<Department> get departmentsRequired =>
      departments ?? (throw StateError('departments is required but was null'));
  bool get hasDepartments => departments?.isNotEmpty ?? false;
  bool get noDepartments => departments?.isEmpty ?? true;
}

enum Company$ { name, headquarters, departments }

class CompanyPatch extends PatchBase<Company, Company$> {
  Company applyTo(Company entity) {
    return entity.patchWithCompany(patchInput: this);
  }

  CompanyPatch withName(String? value) {
    patchMap[Company$.name] = value;
    return this;
  }

  CompanyPatch withHeadquarters(Address? value) {
    patchMap[Company$.headquarters] = value;
    return this;
  }

  CompanyPatch withHeadquartersPatch(AddressPatch patch) {
    patchMap[Company$.headquarters] = patch;
    return this;
  }

  CompanyPatch withHeadquartersPatchFunc(
    AddressPatch Function(AddressPatch) patch,
  ) {
    patchMap[Company$.headquarters] = (dynamic current) {
      var currentPatch = AddressPatch();
      return patch(currentPatch).applyTo(current as Address);
    };
    return this;
  }

  CompanyPatch withDepartments(List<Department>? value) {
    patchMap[Company$.departments] = value;
    return this;
  }
}

extension CompanyCompareE on Company {
  Map<String, dynamic> compareToCompany(Company other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (headquarters != other.headquarters) {
      diff['headquarters'] = () => other.headquarters;
    }
    if (departments != other.departments) {
      diff['departments'] = () => other.departments;
    }
    return diff;
  }
}

class Department {
  final String name;
  final Person manager;
  final int employeeCount;

  Department({
    required this.name,
    required this.manager,
    required this.employeeCount,
  });

  Department copyWith({String? name, Person? manager, int? employeeCount}) {
    return Department(
      name: name ?? this.name,
      manager: manager ?? this.manager,
      employeeCount: employeeCount ?? this.employeeCount,
    );
  }

  Department copyWithDepartment({
    String? name,
    Person? manager,
    int? employeeCount,
  }) {
    return copyWith(name: name, manager: manager, employeeCount: employeeCount);
  }

  Department patchWithDepartment({DepartmentPatch? patchInput}) {
    final _patcher = patchInput ?? DepartmentPatch();
    final _patchMap = _patcher.patchMap;
    return Department(
      name: _patchMap.containsKey(Department$.name)
          ? (_patchMap[Department$.name] is Function)
                ? _patchMap[Department$.name](this.name)
                : (_patchMap[Department$.name] is Patch)
                ? _patchMap[Department$.name].applyTo(this.name)
                : _patchMap[Department$.name]
          : this.name,
      manager: _patchMap.containsKey(Department$.manager)
          ? (_patchMap[Department$.manager] is Function)
                ? _patchMap[Department$.manager](this.manager)
                : (_patchMap[Department$.manager] is Patch)
                ? _patchMap[Department$.manager].applyTo(this.manager)
                : _patchMap[Department$.manager]
          : this.manager,
      employeeCount: _patchMap.containsKey(Department$.employeeCount)
          ? (_patchMap[Department$.employeeCount] is Function)
                ? _patchMap[Department$.employeeCount](this.employeeCount)
                : (_patchMap[Department$.employeeCount] is Patch)
                ? _patchMap[Department$.employeeCount].applyTo(
                    this.employeeCount,
                  )
                : _patchMap[Department$.employeeCount]
          : this.employeeCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Department &&
        name == other.name &&
        manager == other.manager &&
        employeeCount == other.employeeCount;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.manager, this.employeeCount);
  }

  @override
  String toString() {
    return 'Department(' +
        'name: ${name}' +
        ', ' +
        'manager: ${manager}' +
        ', ' +
        'employeeCount: ${employeeCount})';
  }
}

extension DepartmentPropertyHelpers on Department {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

enum Department$ { name, manager, employeeCount }

class DepartmentPatch extends PatchBase<Department, Department$> {
  Department applyTo(Department entity) {
    return entity.patchWithDepartment(patchInput: this);
  }

  DepartmentPatch withName(String? value) {
    patchMap[Department$.name] = value;
    return this;
  }

  DepartmentPatch withManager(Person? value) {
    patchMap[Department$.manager] = value;
    return this;
  }

  DepartmentPatch withManagerPatch(PersonPatch patch) {
    patchMap[Department$.manager] = patch;
    return this;
  }

  DepartmentPatch withManagerPatchFunc(
    PersonPatch Function(PersonPatch) patch,
  ) {
    patchMap[Department$.manager] = (dynamic current) {
      var currentPatch = PersonPatch();
      return patch(currentPatch).applyTo(current as Person);
    };
    return this;
  }

  DepartmentPatch withEmployeeCount(int? value) {
    patchMap[Department$.employeeCount] = value;
    return this;
  }
}

extension DepartmentCompareE on Department {
  Map<String, dynamic> compareToDepartment(Department other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (manager != other.manager) {
      diff['manager'] = () => other.manager;
    }
    if (employeeCount != other.employeeCount) {
      diff['employeeCount'] = () => other.employeeCount;
    }
    return diff;
  }
}
