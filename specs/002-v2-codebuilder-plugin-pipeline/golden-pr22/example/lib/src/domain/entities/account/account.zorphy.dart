// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'account.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Account {
  final String username;
  final UserStatus status;
  final DateTime createdAt;

  Account({
    required this.username,
    required this.status,
    required this.createdAt,
  });

  Account copyWith({
    String? username,
    UserStatus? status,
    DateTime? createdAt,
  }) {
    return Account(
      username: username ?? this.username,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Account copyWithAccount({
    String? username,
    UserStatus? status,
    DateTime? createdAt,
  }) {
    return copyWith(username: username, status: status, createdAt: createdAt);
  }

  Account patchWithAccount({AccountPatch? patchInput}) {
    final _patcher = patchInput ?? AccountPatch();
    final _patchMap = _patcher.patchMap;
    return Account(
      username: _patchMap.containsKey(Account$.username)
          ? (_patchMap[Account$.username] is Function)
                ? _patchMap[Account$.username](this.username)
                : (_patchMap[Account$.username] is Patch)
                ? _patchMap[Account$.username].applyTo(this.username)
                : _patchMap[Account$.username]
          : this.username,
      status: _patchMap.containsKey(Account$.status)
          ? (_patchMap[Account$.status] is Function)
                ? _patchMap[Account$.status](this.status)
                : (_patchMap[Account$.status] is Patch)
                ? _patchMap[Account$.status].applyTo(this.status)
                : _patchMap[Account$.status]
          : this.status,
      createdAt: _patchMap.containsKey(Account$.createdAt)
          ? (_patchMap[Account$.createdAt] is Function)
                ? _patchMap[Account$.createdAt](this.createdAt)
                : (_patchMap[Account$.createdAt] is Patch)
                ? _patchMap[Account$.createdAt].applyTo(this.createdAt)
                : _patchMap[Account$.createdAt]
          : this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        username == other.username &&
        status == other.status &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(this.username, this.status, this.createdAt);
  }

  @override
  String toString() {
    return 'Account(' +
        'username: ${username}' +
        ', ' +
        'status: ${status}' +
        ', ' +
        'createdAt: ${createdAt})';
  }

  /// Creates a [Account] instance from JSON
  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AccountToJson(this);
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

extension AccountPropertyHelpers on Account {
  bool get hasUsername => username.isNotEmpty;
  bool get noUsername => username.isEmpty;
  bool get isStatusActive => status == UserStatus.active;
  bool get isStatusInactive => status == UserStatus.inactive;
  bool get isStatusSuspended => status == UserStatus.suspended;
  bool get isStatusPending => status == UserStatus.pending;
}

extension AccountSerialization on Account {
  Map<String, dynamic> toJson() => _$AccountToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AccountToJson(this);
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

enum Account$ { username, status, createdAt }

class AccountPatch extends PatchBase<Account, Account$> {
  Account applyTo(Account entity) {
    return entity.patchWithAccount(patchInput: this);
  }

  AccountPatch withUsername(String? value) {
    patchMap[Account$.username] = value;
    return this;
  }

  AccountPatch withStatus(UserStatus? value) {
    patchMap[Account$.status] = value;
    return this;
  }

  AccountPatch withCreatedAt(DateTime? value) {
    patchMap[Account$.createdAt] = value;
    return this;
  }
}

/// Field descriptors for [Account] query construction
abstract final class AccountFields {
  static String _$getusername(Account e) => e.username;
  static const username = Field<Account, String>('username', _$getusername);
  static UserStatus _$getstatus(Account e) => e.status;
  static const status = Field<Account, UserStatus>('status', _$getstatus);
  static DateTime _$getcreatedAt(Account e) => e.createdAt;
  static const createdAt = Field<Account, DateTime>(
    'createdAt',
    _$getcreatedAt,
  );
}

extension AccountCompareE on Account {
  Map<String, dynamic> compareToAccount(Account other) {
    final Map<String, dynamic> diff = {};

    if (username != other.username) {
      diff['username'] = () => other.username;
    }
    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    return diff;
  }
}
