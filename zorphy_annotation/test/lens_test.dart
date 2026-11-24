import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

// ────────────────────────────────────────────────────────────────────
// Fixtures — a two-level state tree, mirroring the shape the issue
// names (`ProductUiState.lenses.editDraft.then(...)`).
// ────────────────────────────────────────────────────────────────────

class Draft {
  final String title;
  final double price;

  const Draft(this.title, this.price);

  Draft copyWith({String? title, double? price}) =>
      Draft(title ?? this.title, price ?? this.price);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Draft && other.title == title && other.price == price;

  @override
  int get hashCode => Object.hash(title, price);

  @override
  String toString() => 'Draft($title, $price)';
}

class UiState {
  final Draft editDraft;
  final int selectedTab;

  const UiState(this.editDraft, this.selectedTab);

  UiState copyWith({Draft? editDraft, int? selectedTab}) =>
      UiState(editDraft ?? this.editDraft, selectedTab ?? this.selectedTab);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiState &&
          other.editDraft == editDraft &&
          other.selectedTab == selectedTab;

  @override
  int get hashCode => Object.hash(editDraft, selectedTab);
}

/// Hand-written mirror of what the generator emits for `UiState`.
final class UiStateLenses {
  const UiStateLenses();

  ZorphyLens<UiState, Draft> get editDraft => const ZorphyLens<UiState, Draft>(
    path: '/editDraft',
    get: _getEditDraft,
    set: _setEditDraft,
  );

  ZorphyLens<UiState, int> get selectedTab => const ZorphyLens<UiState, int>(
    path: '/selectedTab',
    get: _getSelectedTab,
    set: _setSelectedTab,
  );

  static Draft _getEditDraft(UiState root) => root.editDraft;

  static UiState _setEditDraft(UiState root, Draft value) =>
      root.copyWith(editDraft: value);

  static int _getSelectedTab(UiState root) => root.selectedTab;

  static UiState _setSelectedTab(UiState root, int value) =>
      root.copyWith(selectedTab: value);
}

/// Hand-written mirror of what the generator emits for `Draft`.
final class DraftLenses {
  const DraftLenses();

  ZorphyLens<Draft, String> get title => const ZorphyLens<Draft, String>(
    path: '/title',
    get: _getTitle,
    set: _setTitle,
  );

  ZorphyLens<Draft, double> get price => const ZorphyLens<Draft, double>(
    path: '/price',
    get: _getPrice,
    set: _setPrice,
  );

  static String _getTitle(Draft root) => root.title;

  static Draft _setTitle(Draft root, String value) =>
      root.copyWith(title: value);

  static double _getPrice(Draft root) => root.price;

  static Draft _setPrice(Draft root, double value) =>
      root.copyWith(price: value);
}

void main() {
  const root = UiState(Draft('widget', 10.0), 2);

  group('ZorphyLens — read/write', () {
    test('get reads the focused value', () {
      expect(
        const UiStateLenses().editDraft.get(root),
        const Draft('widget', 10.0),
      );
      expect(const UiStateLenses().selectedTab.get(root), 2);
    });

    test('set replaces the focused value and leaves siblings untouched', () {
      final updated = const UiStateLenses().selectedTab.set(root, 5);
      expect(updated.selectedTab, 5);
      expect(updated.editDraft, root.editDraft);
      // The original is immutable and unchanged.
      expect(root.selectedTab, 2);
    });

    test('set creates a NEW root (never mutates in place)', () {
      final updated = const UiStateLenses().selectedTab.set(root, 5);
      expect(identical(updated, root), isFalse);
    });

    test('path is a JSON-Pointer to the focused field', () {
      expect(const UiStateLenses().editDraft.path, '/editDraft');
      expect(const DraftLenses().price.path, '/price');
    });
  });

  group('ZorphyLens.then — composition', () {
    final composed = const UiStateLenses().editDraft.then(
      const DraftLenses().price,
    );

    test('composed path concatenates parent and child pointers', () {
      expect(composed.path, '/editDraft/price');
    });

    test('composed get reads through both levels', () {
      expect(composed.get(root), 10.0);
    });

    test('composed set updates the nested value and preserves siblings', () {
      final updated = composed.set(root, 4.5);
      expect(updated.editDraft.price, 4.5);
      expect(updated.editDraft.title, 'widget');
      expect(updated.selectedTab, 2);
    });

    test('composition is associative — (a.then(b)).then(c) reads/writes the '
        'same leaf as a.then(b.then(c))', () {
      final leftAssoc = const UiStateLenses().editDraft
          .then(const DraftLenses().title)
          .then(
            const ZorphyLens<String, String>(
              path: '/0',
              get: _firstChar,
              set: _replaceFirstChar,
            ),
          );

      expect(leftAssoc.path, '/editDraft/title/0');
      expect(leftAssoc.get(root), 'w');
      expect(leftAssoc.set(root, 'W').editDraft.title, 'Widget');
    });
  });

  group('ZorphyLens laws', () {
    final lens = const UiStateLenses().editDraft;

    test('put-get: get(set(root, v)) == v', () {
      const value = Draft('updated', 3.0);
      expect(lens.get(lens.set(root, value)), value);
    });

    test('get-put: set(root, get(root)) == root', () {
      expect(lens.set(root, lens.get(root)), root);
    });

    test('put-put: set(set(root, a), b) == set(root, b)', () {
      const a = Draft('a', 1.0);
      const b = Draft('b', 2.0);
      expect(lens.set(lens.set(root, a), b), lens.set(root, b));
    });

    test('composed lenses obey the same laws', () {
      final composed = const UiStateLenses().editDraft.then(
        const DraftLenses().price,
      );
      expect(composed.get(composed.set(root, 7.25)), 7.25);
      expect(composed.set(root, composed.get(root)), root);
    });
  });

  group('ZorphyLens — value semantics', () {
    test('a const-constructed lens is canonicalized (identical instance)', () {
      expect(
        identical(
          const ZorphyLens<UiState, int>(
            path: '/selectedTab',
            get: UiStateLenses._getSelectedTab,
            set: UiStateLenses._setSelectedTab,
          ),
          const ZorphyLens<UiState, int>(
            path: '/selectedTab',
            get: UiStateLenses._getSelectedTab,
            set: UiStateLenses._setSelectedTab,
          ),
        ),
        isTrue,
      );
    });

    test('then() returns a lens carrying the composed path and behaviour', () {
      final composed = const ZorphyLens<UiState, Draft>(
        path: '/editDraft',
        get: UiStateLenses._getEditDraft,
        set: UiStateLenses._setEditDraft,
      ).then(const DraftLenses().price);

      expect(composed, isA<ZorphyLens<UiState, double>>());
      expect(composed.path, '/editDraft/price');
    });
  });
}

String _firstChar(String value) => value.isEmpty ? '' : value[0];

String _replaceFirstChar(String value, String first) =>
    value.isEmpty ? first : '$first${value.substring(1)}';
