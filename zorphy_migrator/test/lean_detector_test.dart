import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy_migrator/src/lean_detector.dart';

/// The lean detector must drop only the generated helpers nothing consumes,
/// keep every helper the package still references, and never touch a class
/// whose use it cannot prove.
void main() {
  final fixtureDir = p.join('test', 'fixtures', 'lean');

  List<String> fixtureFiles() =>
      Directory(fixtureDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.absolute.path)
          .toList();

  late SymbolIndex symbols;
  late List<LeanProposal> proposals;

  setUpAll(() async {
    final files = fixtureFiles();
    symbols = await LeanDetector.collectSymbols(files);
    proposals = await LeanDetector().detect(files, symbols: symbols);
  });

  LeanProposal proposalFor(String className) {
    final match = proposals.where((p) => p.className == className).toList();
    expect(match, hasLength(1), reason: 'expected one $className proposal');
    return match.single;
  }

  test('finds every annotated class in the fixture', () {
    expect(
      proposals.map((p) => p.className),
      containsAll(<String>['DeadClass', 'LiveClass', 'RemoteJsonModel']),
    );
  });

  group('a class nothing references', () {
    test('drops every feature it asks for', () {
      final proposal = proposalFor('DeadClass');
      expect(proposal.used, isEmpty);
      expect(proposal.isLive, isFalse);
    });

    test('downgrades to the lean preset', () {
      expect(
        proposalFor('DeadClass').proposedSource,
        contains('ZorphyPreset.lean'),
      );
    });

    test('carries unrelated arguments over verbatim', () {
      // `autoId` is not a feature flag; losing it would change behaviour.
      expect(proposalFor('DeadClass').proposedSource, contains('autoId: true'));
    });

    test('is not already lean, so it yields a proposal', () {
      expect(proposalFor('DeadClass').alreadyLean, isFalse);
    });
  });

  group('a class another file uses', () {
    test('stays live, so its preset is left alone', () {
      final proposal = proposalFor('LiveClass');
      expect(proposal.isLive, isTrue);
      expect(proposal.proposedSource, isNot(contains('ZorphyPreset')));
    });

    test('keeps the patch flag the consumer names', () {
      expect(proposalFor('LiveClass').used, contains(LeanFeature.patch));
    });

    test('drops only the filter flag nothing names', () {
      final proposal = proposalFor('LiveClass');
      expect(proposal.used, isNot(contains(LeanFeature.filter)));
      expect(proposal.proposedSource, '@Zorphy(generatePatch: true)');
    });
  });

  group('json stays when the class is consumed elsewhere', () {
    test(
      'an instance-only toJson() usage in another file keeps generateJson',
      () {
        final proposal = proposalFor('RemoteJsonModel');
        expect(proposal.used, contains(LeanFeature.json));
        expect(proposal.proposedSource, '@Zorphy(generateJson: true)');
        expect(proposal.alreadyLean, isTrue);
      },
    );
  });

  group('a class consumed only from its own file', () {
    test('stays live, so nothing is dropped', () {
      final proposal = proposalFor('LocalUse');
      expect(proposal.isLive, isTrue);
      expect(proposal.alreadyLean, isTrue);
    });

    test('keeps json even though only toJson() proves the use', () {
      expect(proposalFor('LocalUse').used, contains(LeanFeature.json));
    });
  });

  group('symbol matching is class-attributed', () {
    test('a helper name only counts for its own class', () {
      final all = symbols.values.fold(<String>{}, (all, counts) {
        all.addAll(counts.keys);
        return all;
      });
      // `LiveClassPatch` exists in the fixture; it must not make
      // `RemoteJsonModel` look like it uses patch.
      expect(all, contains('LiveClassPatch'));
      expect(
        LeanFeature.patch.symbolsFor('RemoteJsonModel'),
        isNot(contains('LiveClassPatch')),
      );
    });
  });

  group('leanReplacements', () {
    test('skips classes that are already lean', () {
      final replacements = leanReplacements(proposals);
      final edited = proposals
          .where((p) => !p.alreadyLean)
          .map((p) => p.offset)
          .toSet();
      expect(replacements.map((r) => r.start).toSet(), edited);
    });
  });
}
