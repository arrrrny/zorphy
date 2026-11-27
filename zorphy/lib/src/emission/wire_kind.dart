/// The exhaustive vocabulary of field kinds the three wire emitters classify.
///
/// This is the SINGLE source of truth behind the wire-capability matrix's
/// drift gate (`test/release/wire_capability_matrix_test.dart`). Each emitter
/// exposes the subset of [WireKind] values its classifier branches handle via
/// `classifiedKinds`; the matrix test derives the expected "recognized kinds"
/// set from the union of those three sets instead of a second hand-written
/// literal. Adding a classifier branch to an emitter therefore requires adding
/// its [WireKind] here and a matching matrix row, or the completeness gate
/// fails — cross-emitter drift becomes unmergeable instead of invisible.
///
/// Every value must have a distinct [matrixKey]: that key is literally the
/// `WireRow.kind` string the matrix uses, so a mismatch is a hard failure.
enum WireKind {
  string('String'),
  integer('int'),
  boolean('bool'),
  doubleKind('double'),
  numKind('num'),
  dateTime('DateTime'),
  duration('Duration'),
  enumeration('enum'),
  uint8List('Uint8List'),
  uri('Uri'),
  nestedEntity('nested entity'),
  typeParam('generic type param (T)'),
  list('List<T>'),
  stringKeyMap('Map<String, V>'),
  set('Set<T>'),
  nonStringKeyMap('Map<K, V> (non-String key)'),
  scalarCatchAll('scalar catch-all'),
  listEnum('List<enum>'),
  stringKeyEnumMap('Map<String, enum>');

  /// The exact `WireRow.kind` string this classification maps to.
  final String matrixKey;

  const WireKind(this.matrixKey);
}

/// The matrix keys of every [WireKind] — the derived recognized-kinds set.
Set<String> get allWireKindKeys =>
    WireKind.values.map((k) => k.matrixKey).toSet();

/// Kinds handled by [BoundaryCodecEmitter]'s `_Shape` classifier.
///
/// `_Shape.scalar` is the open-ended catch-all: `String`, `int`, `bool`,
/// enums, `Duration`, `Uint8List`, `Uri` and non-String-key `Map<K,V>` all
/// land there. `_Shape.list` covers `List<T>`; `Set<T>` is NOT special-cased
/// by the boundary classifier and currently falls through to scalar — the
/// matrix row for `Set<T>` is therefore an omission on the boundary side.
const Set<WireKind> boundaryClassifiedKinds = <WireKind>{
  WireKind.string,
  WireKind.integer,
  WireKind.boolean,
  WireKind.doubleKind,
  WireKind.numKind,
  WireKind.dateTime,
  WireKind.duration,
  WireKind.enumeration,
  WireKind.uint8List,
  WireKind.uri,
  WireKind.nestedEntity,
  WireKind.typeParam,
  WireKind.list,
  WireKind.stringKeyMap,
  WireKind.nonStringKeyMap,
  WireKind.scalarCatchAll,
  WireKind.listEnum,
  WireKind.stringKeyEnumMap,
};

/// Kinds handled by `PolymorphicPatchEmitter` / `ZorphyPatchWire`'s helpers.
const Set<WireKind> patchClassifiedKinds = <WireKind>{
  WireKind.string,
  WireKind.integer,
  WireKind.boolean,
  WireKind.doubleKind,
  WireKind.numKind,
  WireKind.dateTime,
  WireKind.duration,
  WireKind.enumeration,
  WireKind.uint8List,
  WireKind.uri,
  WireKind.nestedEntity,
  WireKind.list,
  WireKind.stringKeyMap,
  WireKind.nonStringKeyMap,
  WireKind.scalarCatchAll,
  WireKind.listEnum,
  WireKind.stringKeyEnumMap,
};

/// Kinds handled by [MockFixtureEmitter]'s `_defaultSeedValue` classifier.
const Set<WireKind> seedClassifiedKinds = <WireKind>{
  WireKind.string,
  WireKind.integer,
  WireKind.boolean,
  WireKind.doubleKind,
  WireKind.numKind,
  WireKind.dateTime,
  WireKind.duration,
  WireKind.enumeration,
  WireKind.uint8List,
  WireKind.uri,
  WireKind.list,
  WireKind.set,
  WireKind.stringKeyMap,
  WireKind.nonStringKeyMap,
  WireKind.scalarCatchAll,
};

/// The kinds ANY emitter classifies — the derivation behind the drift gate.
Set<String> get recognizedWireKindKeys => <WireKind>{
  ...boundaryClassifiedKinds,
  ...patchClassifiedKinds,
  ...seedClassifiedKinds,
}.map((k) => k.matrixKey).toSet();
