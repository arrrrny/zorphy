// Behavioral checks for issue #131 (`copyWithField`). Executed by
// zorphy/test/generation/issue_131_copywithfield_test.dart via
// `dart run` (cwd: zorphy/example) because the zorphy test package
// cannot import the example package's generated code directly.
//
// Exit code 0 = all checks passed. Any failure prints FAIL and exits 1.
import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy_example/various/issue_131_copywithfield_example.dart';

final List<String> failures = <String>[];

void check(String name, bool condition) {
  if (condition) {
    print('PASS: $name');
  } else {
    failures.add(name);
    print('FAIL: $name');
  }
}

void main() {
  // ── Single-field flip (non-generic entity) ──────────────────────
  final step = WalkthroughStep(
    id: 's1',
    title: 'Read the docs',
    position: 3,
    completed: false,
    note: 'chapter 2',
  );

  final toggled = step.copyWithField(WalkthroughStepFields.completed, true);
  check(
    'toggle returns a new instance',
    toggled.completed == true && !identical(toggled, step),
  );
  check('flipped field is replaced', toggled.completed == true);
  check(
    'other fields are preserved',
    toggled.id == 's1' &&
        toggled.title == 'Read the docs' &&
        toggled.position == 3 &&
        toggled.note == 'chapter 2',
  );
  check(
    'toggle equals copyWith(completed: true)',
    toggled == step.copyWith(completed: true),
  );

  final retitled = step.copyWithField(
    WalkthroughStepFields.title,
    'Write the docs',
  );
  check(
    'string field flip equals copyWith',
    retitled.title == 'Write the docs' && retitled == step.copyWith(
      title: 'Write the docs',
    ),
  );

  final repositioned = step.copyWithField(WalkthroughStepFields.position, 7);
  check(
    'int field flip equals copyWith',
    repositioned.position == 7 && repositioned == step.copyWith(position: 7),
  );

  final noted = step.copyWithField(WalkthroughStepFields.note, 'done');
  check(
    'nullable field flip equals copyWith',
    noted.note == 'done' && noted == step.copyWith(note: 'done'),
  );

  // copyWith `??` semantics: a null value keeps the current value.
  final kept = step.copyWithField(WalkthroughStepFields.note, null);
  check('null value keeps current value', kept == step);

  // ── Type safety ─────────────────────────────────────────────────
  // A dynamically typed selector (zuraffa's ToggleParams shape:
  // `Field<Entity, dynamic>`) must fail the in-method cast when the
  // value does not match the field's real type.
  final Field<WalkthroughStep, dynamic> dynPosition =
      WalkthroughStepFields.position;
  TypeError? typeError;
  try {
    step.copyWithField(dynPosition, 'not an int');
  } on TypeError catch (e) {
    typeError = e;
  }
  check('wrongly typed value throws TypeError', typeError != null);

  ArgumentError? unknownFieldError;
  try {
    step.copyWithField(const Field<WalkthroughStep, String>('nope'), 'x');
  } on ArgumentError catch (e) {
    unknownFieldError = e;
  }
  check('unknown selector throws ArgumentError', unknownFieldError != null);

  ArgumentError? foreignFieldError;
  try {
    // 'label' is a ProgressBox field, not a WalkthroughStep field.
    step.copyWithField(const Field<WalkthroughStep, dynamic>('label'), 'x');
  } on ArgumentError catch (e) {
    foreignFieldError = e;
  }
  check('foreign entity field throws ArgumentError', foreignFieldError != null);

  // ── Immutability of the receiver ────────────────────────────────
  check(
    'original entity is untouched',
    step.completed == false &&
        step.title == 'Read the docs' &&
        step.position == 3 &&
        step.note == 'chapter 2',
  );

  // ── Generic entity ──────────────────────────────────────────────
  final box = ProgressBox<int>(value: 42, label: 'answer');

  final relabeled = box.copyWithField(
    ProgressBoxFields.label<int>(),
    'renamed',
  );
  check(
    'generic entity: string field flip',
    relabeled.label == 'renamed' && relabeled.value == 42,
  );

  final revalued = box.copyWithField(
    ProgressBoxFields.value<int>(),
    7,
  );
  check('generic entity: typed parameter flip', revalued.value == 7);
  check(
    'generic entity: equals copyWith(value: 7)',
    revalued == box.copyWith(value: 7),
  );

  ArgumentError? genericUnknownError;
  try {
    box.copyWithField(const Field<ProgressBox<int>, dynamic>('nope'), 'x');
  } on ArgumentError catch (e) {
    genericUnknownError = e;
  }
  check('generic entity: unknown selector throws', genericUnknownError != null);

  // ── Summary ─────────────────────────────────────────────────────
  if (failures.isEmpty) {
    print('ALL CHECKS PASSED');
    return;
  }
  print('${failures.length} CHECK(S) FAILED');
  // Uncaught on purpose: the non-zero exit code is what the driving
  // test asserts on.
  throw StateError('${failures.length} copyWithField check(s) failed');
}
