# TDD Test List — Issue #138

Bug: factory constructors emit duplicated parameters (growing-prefix
duplication) for entities whose static factories have parameters the
analyzer cannot resolve on a first-generation build.

## Behavior to pin (acceptance criteria)

1. A static factory whose later parameter type is unresolved (InvalidType)
   must recover exactly that parameter's own type — never a fragment that
   includes preceding sibling parameters.
2. The generated `factory X.y(...)` must declare each parameter exactly
   once, in source order, with `required` preserved.
3. Recovery must keep the pre-existing shapes working: simple
   (`SubType`), nullable (`BaseType?`), and generic
   (`Map<String, int>`) parameter types.

## Tests

| Test | File | Status before fix |
|------|------|-------------------|
| later param of multi-param factory does not swallow siblings (#138) | `zorphy/test/generation/polymorphic_factory_param_recovery_test.dart` | RED (returns `String url,\n required UrlEndpoint`) |
| create declares each parameter exactly once | `zorphy/test/generation/issue_138_static_factory_params_test.dart` | RED |
| fromUrlSpark declares each parameter exactly once | `zorphy/test/generation/issue_138_static_factory_params_test.dart` | RED |
| factory parameters keep source order and required keywords | `zorphy/test/generation/issue_138_static_factory_params_test.dart` | green before (weak — pins order) |
| recovered parameter types match the source declarations | `zorphy/test/generation/issue_138_static_factory_params_test.dart` | RED |
| build_runner end-to-end on `example/lib/various/issue138_*.dart` | manual/CI smoke | RED (6/3 params instead of 3/2, `Duplicated parameter name`) |
