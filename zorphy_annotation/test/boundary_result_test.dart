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
  });
}
