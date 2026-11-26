import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

// Hand-written mirror of what the generator emits for an entity with a
// nested value field and a nested iterable field (issue #303).
final class Profile {
  final int age;
  const Profile(this.age);
}

final class User {
  final String id;
  final Profile? profile;
  final List<String>? tags;

  const User(this.id, this.profile, [this.tags]);
}

final class ProfileFields {
  static const ZorphyField<Profile, int> age = ZorphyField<Profile, int>(
    name: 'age',
    jsonKey: 'age',
    pointer: '/age',
    get: _getAge,
    set: _setAge,
  );
  static int _getAge(Profile p) => p.age;
  static Profile _setAge(Profile p, int v) => Profile(v);
}

final class UserFields {
  static const ZorphyField<User, Profile?> profile =
      ZorphyField<User, Profile?>(
        name: 'profile',
        jsonKey: 'profile',
        pointer: '/profile',
        get: _getProfile,
        set: _setProfile,
      );
  static const ZorphyField<User, List<String>?> tags =
      ZorphyField<User, List<String>?>(
        name: 'tags',
        jsonKey: 'tags',
        pointer: '/tags',
        get: _getTags,
        set: _setTags,
      );

  static Profile? _getProfile(User u) => u.profile;
  static User _setProfile(User u, Profile? v) => User(u.id, v, u.tags);
  static List<String>? _getTags(User u) => u.tags;
  static User _setTags(User u, List<String>? v) => User(u.id, u.profile, v);

  static ZorphyField<User, Object?>? byPointer(String pointer) =>
      switch (pointer) {
        '/profile' => profile.asObject,
        '/tags' => tags.asObject,
        _ => null,
      };
}

void main() {
  const adult = User('a', Profile(30), ['admin', 'beta']);
  const child = User('c', Profile(8), ['beta']);
  const noProfile = User('n', null, null);

  group('ZorphyNested', () {
    test('matches a nested value through a predicate over its type', () {
      final f = UserFields.profile.nested(ProfileFields.age.greaterThan(18));
      expect(f.matches(adult), isTrue);
      expect(f.matches(child), isFalse);
    });

    test('matches an Iterable field when ANY element matches', () {
      final f = UserFields.tags.nested(
        const ZorphyEquals<dynamic, Object?>(
          ZorphyField<dynamic, Object?>(
            name: 'itself',
            jsonKey: 'itself',
            pointer: '/',
            get: _self,
            set: _selfSet,
          ),
          'admin',
        ),
      );
      expect(f.matches(adult), isTrue, reason: 'admin is in the tags');
      expect(f.matches(child), isFalse, reason: 'no admin tag');
    });

    test('a null nested value never matches', () {
      final f = UserFields.profile.nested(ProfileFields.age.greaterThan(0));
      expect(f.matches(noProfile), isFalse);
    });

    test('toWire carries the field pointer and the inner predicate', () {
      final f = UserFields.profile.nested(ProfileFields.age.greaterThan(18));
      expect(f.toWire(), {
        'op': 'nested',
        'field': '/profile',
        'filter': {'field': '/age', 'op': 'gt', 'value': 18},
      });
    });

    test('fromWire rebuilds it when given a resolveNested', () {
      final f = UserFields.profile.nested(ProfileFields.age.greaterThan(18));
      final back = ZorphyFilter.fromWire<User>(
        f.toWire(),
        UserFields.byPointer,
        resolveNested: (w) => ZorphyFilter.fromWire<Profile>(
          w,
          (p) => p == '/age' ? ProfileFields.age.asObject : null,
        ),
      );
      expect(back.matches(adult), isTrue);
      expect(back.matches(child), isFalse);
    });

    test('fromWire fails loudly on a nested wire without a resolveNested', () {
      final f = UserFields.profile.nested(ProfileFields.age.greaterThan(18));
      expect(
        () => ZorphyFilter.fromWire<User>(f.toWire(), UserFields.byPointer),
        throwsA(isA<FormatException>()),
      );
    });

    test('composes with and / or / not like every other predicate', () {
      final adult = UserFields.profile.nested(
        ProfileFields.age.greaterThan(18),
      );
      final admin = UserFields.tags.nested(
        const ZorphyEquals<dynamic, Object?>(
          ZorphyField<dynamic, Object?>(
            name: 'itself',
            jsonKey: 'itself',
            pointer: '/',
            get: _self,
            set: _selfSet,
          ),
          'admin',
        ),
      );
      expect(
        adult.and(admin).matches(User('x', Profile(40), ['admin'])),
        isTrue,
      );
      expect(
        adult.and(admin).matches(User('x', Profile(40), ['beta'])),
        isFalse,
      );
      expect(adult.not().matches(child), isTrue);
    });
  });
}

dynamic _self(dynamic v) => v;
dynamic _selfSet(dynamic root, dynamic v) => v;
