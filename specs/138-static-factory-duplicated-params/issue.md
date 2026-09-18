# Bug Issue: Factory constructors emit duplicated parameters (invalid Dart)

- **Slug**: 138-static-factory-duplicated-params
- **Fetched**: 2026-09-17
- **Issue**: 138
- **URL**: https://github.com/arrrrny/zorphy/issues/138
- **State**: open
- **Severity**: unknown
- **Author**: arrrrny
- **Labels**: (none)

## Body

### Summary

On zorphy `master` @ `de4e4e3` (v2.4.0), regenerating an entity whose `@Zorphy` abstract base declares a **`static` factory method** produces `factory X.y({...})` constructors whose parameter lists contain **repeated parameters**, which is invalid Dart:

```
Error: Duplicated parameter name 'url'.
```

Traced with runtime instrumentation inside a scratch copy of the generator. **The spec handed to the emitter is correct; the corruption is introduced by the emission step** (`library.accept(DartEmitter())`). The `#129` parameter-dedup logic is working and is *not* the cause.

### Environment

| | |
|---|---|
| zorphy | `master` @ `de4e4e3` (`chore: release v2.4.0`), consumed via path dependency |
| code_builder | `4.12.0` (zorphy constraint: `^4.10.0`) |
| Dart SDK | 3.13.2 (stable) |
| Flutter | 3.47.2 (stable) |
| OS | macOS (x64) |

### Reproduction

Entity source (`lib/src/domain/entities/zik/zik.dart`) — note the two `static` factories:

```dart
@Zorphy(generateJson: true)
abstract class $Zik {
  String get id;
  $$Spark? get spark;
  String get url;
  $UrlEndpoint get urlEndpoint;

  static Zik create({
    required String url,
    required UrlEndpoint urlEndpoint,
    Spark? spark,
  }) => Zik(
    id: const Uuid().v7(),
    url: url,
    spark: spark,
    urlEndpoint: urlEndpoint,
  );

  static Zik fromUrlSpark({
    required UrlSpark spark,
    required UrlEndpoint urlEndpoint,
  }) => Zik.create(spark: spark, url: spark.url, urlEndpoint: urlEndpoint);
}
```

Command:

```bash
dart run build_runner build --build-filter='lib/src/domain/entities/zik/zik.zorphy.dart'
```

Observed output (invalid — `url` and `urlEndpoint` repeated, and the delegating body only references each name once):

```dart
  factory Zik.create({
    required String url,
    required String url,
    UrlEndpoint urlEndpoint,
    String url,
    UrlEndpoint urlEndpoint,
    Spark? spark,
  }) => $Zik.create(url: url, urlEndpoint: urlEndpoint, spark: spark);

  factory Zik.fromUrlSpark({
    required UrlSpark spark,
    required UrlSpark spark,
    UrlEndpoint urlEndpoint,
  }) => $Zik.fromUrlSpark(spark: spark, urlEndpoint: urlEndpoint);
```

100% reproducible (identical output hash on every run). Not specific to this entity: a second entity with the same shape (`ZikZakConfig.create`, whose 4 source parameters become 7) fails the same way, and 141 generated files in the consuming project fail to compile as a result.

### Evidence 1 — the constructor spec is CORRECT

Instrumented print in `FactoryMethodGenerator._buildFactoryConstructor`, immediately before returning the `Constructor`:

```
[ZDBG] build name=create   raw=[url, urlEndpoint, spark] deduped=[url, urlEndpoint, spark] builtReq=[] builtOpt=[url, urlEndpoint, spark] body=$Zik.create(url: url, urlEndpoint: urlEndpoint, spark: spark)
[ZDBG] build name=fromUrlSpark raw=[spark, urlEndpoint] deduped=[spark, urlEndpoint] builtReq=[] builtOpt=[spark, urlEndpoint] body=$Zik.fromUrlSpark(spark: spark, urlEndpoint: urlEndpoint)
```

Instrumented print in `Orchestrator._mergeMembersIntoClass`, on the final class spec that goes into the `Library`:

```
[ZDBG] class=Zik ctorCount=4 ctors=[null(id,spark,url,urlEndpoint), create(url,urlEndpoint,spark), fromUrlSpark(spark,urlEndpoint), fromJson(json)]
```

Instrumented print at the top of `ZorphyEmitter.emit`, re-reading the `Class` out of `library.body`:

```
[ZDBG-EMITCLASS] name=Zik ctors=null|req:[]|opt:[id/spark/url/urlEndpoint]  ||  create|req:[]|opt:[url/urlEndpoint/spark]  ||  fromUrlSpark|req:[]|opt:[spark/urlEndpoint]  ||  fromJson|req:[json]|opt:[]
```

So the emitter is handed `create` with exactly **3** optional parameters, and `fromUrlSpark` with **2**.

### Evidence 2 — the raw emitter output is already corrupt

Printed between `library.accept(DartEmitter()).toString()` and the `dart_style` format call (`\n` shown as `~`):

```
[ZDBG-RAW] found=true window=factory Zik.create({required String url, required String url,~     UrlEndpoint urlEndpoint, String url,~     UrlEndpoint urlEndpoint,~    Spark? spark, }) => $Zik.create(url: url, urlEndpoint: urlEndpoint, spark: spark);~~factory Zik.fromUrlSpark({required UrlSpark spark, required UrlSpark spark,~     UrlEndpoint urlEndpoint, }) => $Zik.fromUrlSpark(spark: spark, urlEndpoint: urlEndpoint);
```

The duplication is present **before** formatting, and the odd line breaks (`UrlEndpoint urlEndpoint, String url,` on one line, inconsistent leading whitespace) suggest the parameter text is being assembled by concatenation rather than emitted as a single list.

### Shape of the corruption

The emitted parameter sequence is the list of **growing prefixes** concatenated:

- `create` (3 real params) → `[url] + [url, urlEndpoint] + [url, urlEndpoint, spark]` = 6 entries
- `fromUrlSpark` (2 real params) → `[spark] + [spark, urlEndpoint]` = 3 entries

i.e. for `N` real parameters the emitted constructor has `N(N+1)/2` parameters, and the duplicated copies are emitted without the `required` modifier in some positions (e.g. `UrlEndpoint urlEndpoint,` and `String url,`).

### Ruled out

- **`_deduplicateParameters` / `_deduplicateFactories` (#129, commit `8271cea`)** — both run and produce a correct spec (Evidence 1). The fix is real but operates upstream of where the corruption happens, which is why it does not prevent this.
- **The merge subsystem** (`lib/src/merge/`: `MergeOrchestrator`, `merge_strategy.dart`, `ast_diff.dart`, `region_parser.dart`, `declaration_scanner.dart`) — 1066 lines with **no callers anywhere in `lib/`**. Nothing invokes `MergeOrchestrator.merge`, so this is dead code and is not involved. (Worth deleting or wiring up separately.)
- **`_emitViaSpecPipeline` being called twice / two pipelines** — it is called once from `Orchestrator.generate`, and `_emitter.emit(library)` is the only emission path.

### Suggested next step

The defect is downstream of the specs, in the emission step. Two things to check, both consistent with the prefix-concatenation shape:

1. Whether the same `Parameter` / `TypeReference` instances end up shared between a class's constructors — the entity's default constructor also carries `url`/`urlEndpoint` (`null|opt:[id/spark/url/urlEndpoint]`), and code_builder's specs cache their built form.
2. Whether `Constructor`'s parameter list is being rebuilt/appended to while `DartEmitter` walks it, which would account for `[p1] ++ [p1,p2] ++ ...`.

A minimal fixture inside zorphy (one `@Zorphy` abstract class with a `static` factory returning the concrete type, generating twice) should reproduce it without the consuming app.

## Comments

None.
