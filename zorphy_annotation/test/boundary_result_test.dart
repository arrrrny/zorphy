import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

void main() {
  group('BoundaryOk', () {
    test('isOk is true and valueOrNull returns the value', () {
      const result = BoundaryOk<int>(42);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 42);
    });

    test('valueOrNull on an ok boundary of a nullable type keeps null', () {
      const result = BoundaryOk<String?>(null);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });

  group('BoundaryErr', () {
    test('isOk is false and valueOrNull is null', () {
      const result = BoundaryErr<double>(
        targetType: 'double',
        violations: [
          FieldViolation(path: '/price', expected: 'double', actual: 'String'),
        ],
      );
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
    });

    test('carries targetType and violations verbatim', () {
      const violations = [
        FieldViolation(
          path: '/items[2]/price',
          expected: 'double',
          actual: 'String ("free")',
        ),
        FieldViolation(path: '/name', expected: 'String', actual: 'int'),
      ];
      const result = BoundaryErr<String>(
        targetType: 'String',
        violations: violations,
      );
      expect(result.targetType, 'String');
      expect(result.violations, same(violations));
    });
  });

  group('FieldViolation', () {
    test('exposes path, expected and actual', () {
      const v = FieldViolation(
        path: '/items[2]/price',
        expected: 'double',
        actual: 'String ("free")',
      );
      expect(v.path, '/items[2]/price');
      expect(v.expected, 'double');
      expect(v.actual, 'String ("free")');
    });

    test('has value equality on a non-const construction', () {
      final a = _nonConstViolation();
      final b = _nonConstViolation();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs from a violation with another pointer', () {
      expect(
        _nonConstViolation(),
        isNot(equals(_nonConstViolation(path: '/other'))),
      );
    });
  });

  group('value equality', () {
    test('BoundaryOk compares by value (non-const)', () {
      final a = BoundaryOk<List<int>>([1, 2]);
      expect(a, isNot(equals(BoundaryOk<List<int>>([1, 2]))));
      expect(a, equals(BoundaryOk<List<int>>(a.value)));
      final b = BoundaryOk<List<int>>(a.value);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('BoundaryErr compares by targetType and violations (non-const)', () {
      final a = _nonConstErr();
      final b = _nonConstErr();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect({a, b}, hasLength(1));
    });

    test('BoundaryErr differs when the violation list differs', () {
      expect(
        _nonConstErr(),
        isNot(
          equals(
            _nonConstErr(violations: [_nonConstViolation(path: '/elsewhere')]),
          ),
        ),
      );
    });

    test('BoundaryErr differs when targetType differs', () {
      expect(_nonConstErr(), isNot(equals(_nonConstErr(targetType: 'num'))));
    });

    test('BoundaryOk equality is symmetric across type arguments', () {
      final okNum = BoundaryOk<num>(1);
      final okInt = BoundaryOk<int>(1);
      expect(okNum == okInt, isFalse);
      expect(okInt == okNum, isFalse);
      expect({okNum, okInt}, hasLength(2));
      expect(okInt, equals(BoundaryOk<int>(1)));
    });

    test('BoundaryErr equality is symmetric across type arguments', () {
      final errNum = BoundaryErr<num>(
        targetType: 'int',
        violations: [_nonConstViolation()],
      );
      final errInt = _nonConstErr();
      expect(errNum == errInt, isFalse);
      expect(errInt == errNum, isFalse);
      expect({errNum, errInt}, hasLength(2));
      expect(errInt, equals(_nonConstErr()));
    });
  });

  group('fold', () {
    test('calls onOk with the value and returns its result', () {
      const ok = BoundaryOk<int>(7);
      final out = ok.fold<int>((value) => value * 2, (_) => -1);
      expect(out, 14);
    });

    test('calls onErr with the error and returns its result', () {
      const err = BoundaryErr<int>(
        targetType: 'int',
        violations: [
          FieldViolation(path: '/a', expected: 'int', actual: 'String'),
        ],
      );
      final out = err.fold<int>((_) => -1, (e) => e.violations.length);
      expect(out, 1);
    });

    test('works for a nullable success type', () {
      const ok = BoundaryOk<String?>(null);
      final out = ok.fold<bool>((value) => value == null, (_) => false);
      expect(out, isTrue);
    });
  });

  group('getOrThrow', () {
    test('returns the value on BoundaryOk', () {
      const ok = BoundaryOk<int>(5);
      expect(ok.getOrThrow(), 5);
    });

    test('throws a StateError describing the target type on BoundaryErr', () {
      const err = BoundaryErr<int>(
        targetType: 'int',
        violations: [
          FieldViolation(path: '/a', expected: 'int', actual: 'String'),
          FieldViolation(path: '/b', expected: 'int', actual: 'String'),
        ],
      );
      expect(
        () => err.getOrThrow(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('int'), contains('/a'), contains('/b')),
          ),
        ),
      );
    });

    test('mentions the violation count in the thrown message', () {
      const err = BoundaryErr<int>(
        targetType: 'int',
        violations: [
          FieldViolation(path: '/a', expected: 'int', actual: 'String'),
        ],
      );
      expect(
        () => err.getOrThrow(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('1 violation'),
          ),
        ),
      );
    });

    test('reads as a sentence when there are no field violations', () {
      final err = BoundaryErr<int>(
        targetType: 'int',
        violations: <FieldViolation>[],
      );
      expect(err.violations, isEmpty);
      expect(
        () => err.getOrThrow(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('target type int'),
              contains('with no field violations.'),
              isNot(contains('0 violations')),
            ),
          ),
        ),
      );
    });
  });

  group('identity through a runtime decode path', () {
    test('a non-const BoundaryOk carries the value', () {
      final value = [1, 2, 3];
      final ok = BoundaryOk<List<int>>(value);
      expect(ok.isOk, isTrue);
      expect(ok.valueOrNull, same(value));
      expect(ok.getOrThrow(), same(value));
    });

    test('a non-const BoundaryErr folds through the error arm', () {
      final err = _nonConstErr();
      final out = err.fold<int>((_) => -1, (e) => e.violations.length);
      expect(out, 1);
    });
  });
}

FieldViolation _nonConstViolation({String path = '/a'}) =>
    FieldViolation(path: path, expected: 'int', actual: 'String');

BoundaryErr<int> _nonConstErr({
  String targetType = 'int',
  List<FieldViolation>? violations,
}) => BoundaryErr<int>(
  targetType: targetType,
  violations: violations ?? [_nonConstViolation()],
);
