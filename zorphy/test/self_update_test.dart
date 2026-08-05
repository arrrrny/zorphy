import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:zorphy/zorphy_cli.dart';

void main() {
  group('VersionChecker', () {
    group('checkForUpdateSync (version comparison)', () {
      test('major version bump is newer', () {
        final checker = VersionChecker(currentVersion: '1.9.0');
        final result = checker.checkForUpdateSync(
          pubDevResponse: {'latest': {'version': '2.0.0'}},
        );
        expect(result.updateAvailable, isTrue);
        expect(result.latestVersion, equals('2.0.0'));
      });

      test('minor version bump is newer', () {
        final checker = VersionChecker(currentVersion: '2.0.0');
        final result = checker.checkForUpdateSync(
          pubDevResponse: {'latest': {'version': '2.1.0'}},
        );
        expect(result.updateAvailable, isTrue);
      });

      test('patch version bump is newer', () {
        final checker = VersionChecker(currentVersion: '2.0.0');
        final result = checker.checkForUpdateSync(
          pubDevResponse: {'latest': {'version': '2.0.1'}},
        );
        expect(result.updateAvailable, isTrue);
      });

      test('same version is not newer', () {
        final checker = VersionChecker(currentVersion: '2.0.0');
        final result = checker.checkForUpdateSync(
          pubDevResponse: {'latest': {'version': '2.0.0'}},
        );
        expect(result.updateAvailable, isFalse);
      });

      test('older version is not newer', () {
        final checker = VersionChecker(currentVersion: '2.1.0');
        final result = checker.checkForUpdateSync(
          pubDevResponse: {'latest': {'version': '2.0.0'}},
        );
        expect(result.updateAvailable, isFalse);
      });

      test('handles v-prefix in version string', () {
        final checker = VersionChecker(currentVersion: '2.0.0');
        final result = checker.checkForUpdateSync(
          pubDevResponse: {'latest': {'version': 'v2.1.0'}},
        );
        expect(result.updateAvailable, isTrue);
      });

      test('strips pre-release suffix for comparison', () {
        final checker = VersionChecker(currentVersion: '2.0.0');
        final result = checker.checkForUpdateSync(
          pubDevResponse: {'latest': {'version': '2.1.0-beta.1'}},
        );
        expect(result.updateAvailable, isTrue);
      });
    });

    group('checkForUpdate (with mock fetchJson)', () {
      test('reports newer version available', () async {
        final checker = VersionChecker(
          currentVersion: '1.9.0',
          fetchJson: _mockFetchJson({
            'latest': {'version': '2.0.0'},
            'versions': [
              {'version': '2.0.0'},
              {'version': '1.9.0'},
            ],
          }),
        );

        final result = await checker.checkForUpdate();
        expect(result.currentVersion, equals('1.9.0'));
        expect(result.latestVersion, equals('2.0.0'));
        expect(result.updateAvailable, isTrue);
      });

      test('reports already up to date', () async {
        final checker = VersionChecker(
          currentVersion: '2.0.0',
          fetchJson: _mockFetchJson({
            'latest': {'version': '2.0.0'},
            'versions': [{'version': '2.0.0'}],
          }),
        );

        final result = await checker.checkForUpdate();
        expect(result.updateAvailable, isFalse);
        expect(result.latestVersion, equals('2.0.0'));
      });

      test('handles network error gracefully', () async {
        final checker = VersionChecker(
          currentVersion: '2.0.0',
          fetchJson: (url, {timeout}) async {
            throw SocketException('Connection refused');
          },
        );

        final result = await checker.checkForUpdate();
        expect(result.latestVersion, isNull);
        expect(result.updateAvailable, isFalse);
        expect(result.message, contains('Network error'));
      });

      test('handles malformed JSON response', () async {
        final checker = VersionChecker(
          currentVersion: '2.0.0',
          fetchJson: (url, {timeout}) async => '{bad: data',
        );

        final result = await checker.checkForUpdate();
        expect(result.latestVersion, isNull);
        expect(result.message, contains('Failed to parse'));
      });

      test('falls back to versions list when latest field missing', () async {
        final checker = VersionChecker(
          currentVersion: '1.5.0',
          fetchJson: _mockFetchJson({
            'versions': [
              {'version': '2.0.0'},
              {'version': '1.9.0'},
              {'version': '1.5.0'},
            ],
          }),
        );

        final result = await checker.checkForUpdate();
        expect(result.latestVersion, equals('2.0.0'));
        expect(result.updateAvailable, isTrue);
      });

      test('skips prerelease versions in fallback', () async {
        final checker = VersionChecker(
          currentVersion: '1.9.0',
          fetchJson: _mockFetchJson({
            'versions': [
              {'version': '2.1.0-beta'},
              {'version': '2.0.0'},
            ],
          }),
        );

        final result = await checker.checkForUpdate();
        expect(result.latestVersion, equals('2.0.0'));
        expect(result.updateAvailable, isTrue);
      });

      test('passes correct URL to fetchJson', () async {
        String? capturedUrl;
        final checker = VersionChecker(
          currentVersion: '2.0.0',
          fetchJson: (url, {timeout}) async {
            capturedUrl = url;
            return jsonEncode({'latest': {'version': '2.0.0'}});
          },
        );

        await checker.checkForUpdate();
        expect(capturedUrl, equals('https://pub.dev/api/packages/zorphy'));
      });
    });

    group('performUpdate', () {
      test('returns success when dart pub global activate succeeds', () async {
        final checker = VersionChecker(
          currentVersion: '2.0.0',
          processRunner: (exe, args) async {
            expect(exe, equals('dart'));
            expect(args, contains('global'));
            expect(args, contains('activate'));
            expect(args, contains('zorphy'));
            return ProcessResult(0, 0, 'Activated zorphy 2.1.0', '');
          },
        );

        final result = await checker.performUpdate();
        expect(result.success, isTrue);
      });

      test('returns failure when dart pub global activate fails', () async {
        final checker = VersionChecker(
          currentVersion: '2.0.0',
          processRunner: (exe, args) async {
            return ProcessResult(0, 1, '', 'Could not resolve package');
          },
        );

        final result = await checker.performUpdate();
        expect(result.success, isFalse);
        expect(result.exitCode, equals(1));
        expect(result.message, contains('Could not resolve'));
      });

      test('handles exception during process execution', () async {
        final checker = VersionChecker(
          currentVersion: '2.0.0',
          processRunner: (exe, args) async {
            throw ArgumentError('Command not found: $exe');
          },
        );

        final result = await checker.performUpdate();
        expect(result.success, isFalse);
        expect(result.message, contains('Failed to run'));
      });
    });

    group('UpdateCheckResult.toString', () {
      test('formats update available message', () {
        final result = UpdateCheckResult(
          currentVersion: '1.9.0',
          latestVersion: '2.0.0',
          updateAvailable: true,
          message: 'Update available: 1.9.0 → 2.0.0',
        );
        final output = result.toString();
        expect(output, contains('Current version:  1.9.0'));
        expect(output, contains('Latest version:   2.0.0'));
        expect(output, contains('newer version is available'));
      });

      test('formats up-to-date message', () {
        final result = UpdateCheckResult(
          currentVersion: '2.0.0',
          latestVersion: '2.0.0',
          updateAvailable: false,
          message: 'Already on the latest version.',
        );
        final output = result.toString();
        expect(output, contains('up to date'));
      });

      test('formats error when no latest version', () {
        final result = UpdateCheckResult(
          currentVersion: '2.0.0',
          updateAvailable: false,
          message: 'Network error',
        );
        final output = result.toString();
        expect(output, contains('Could not determine'));
      });
    });

    group('UpdateResult.toString', () {
      test('formats success message', () {
        final result = UpdateResult(
          success: true,
          newVersion: '2.1.0',
          message: 'Updated successfully',
        );
        final output = result.toString();
        expect(output, contains('Update successful'));
        expect(output, contains('2.1.0'));
      });

      test('formats failure message', () {
        final result = UpdateResult(
          success: false,
          exitCode: 1,
          message: 'Activation failed',
        );
        final output = result.toString();
        expect(output, contains('Update failed'));
        expect(output, contains('Exit code: 1'));
      });

      test('formats success without verifiable version', () {
        final result = UpdateResult(
          success: true,
          message: 'Update applied',
        );
        final output = result.toString();
        expect(output, contains('Update successful'));
        expect(output, isNot(contains('New version')));
      });
    });
  });
}

/// Helper: create a [FetchJsonFunction] that returns the given JSON map
/// encoded as a string.
FetchJsonFunction _mockFetchJson(Map<String, dynamic> json) {
  return (url, {timeout}) async => jsonEncode(json);
}
