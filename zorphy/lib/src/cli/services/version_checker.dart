/// Version checking and self-update service for the zorphy CLI.
///
/// Queries the pub.dev API to check for the latest published version
/// and optionally runs `dart pub global activate` to update.
library;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../models/update_result.dart';

/// Functional type for fetching JSON from a URL.
/// Returns the response body as a string, or throws on network/HTTP errors.
/// Used to allow injecting a mock in tests without implementing HttpClientResponse.
typedef FetchJsonFunction = Future<String> Function(
  String url, {
  Duration? timeout,
});

/// Functional type for running a subprocess.
typedef RunProcessFunction = Future<ProcessResult> Function(
  String executable,
  List<String> args,
);

/// Service that checks the latest published version of zorphy on pub.dev
/// and can perform a self-update via `dart pub global activate`.
class VersionChecker {
  /// The current CLI version (from the _version constant).
  final String currentVersion;

  /// The package name on pub.dev.
  final String packageName;

  /// The pub.dev API URL template.
  final String apiBaseUrl;

  /// Overrideable JSON fetcher for testing. Defaults to real HTTP.
  final FetchJsonFunction? fetchJson;

  /// Overrideable process runner for testing. Defaults to real Process.run.
  final RunProcessFunction? processRunner;

  VersionChecker({
    required this.currentVersion,
    this.packageName = 'zorphy',
    this.apiBaseUrl = 'https://pub.dev',
    this.fetchJson,
    this.processRunner,
  });

  /// Check the latest published version on pub.dev.
  ///
  /// Returns an [UpdateCheckResult] with version comparison info.
  Future<UpdateCheckResult> checkForUpdate() async {
    final url = '$apiBaseUrl/api/packages/$packageName';

    try {
      final body = await _doFetchJson(url);

      final json = jsonDecode(body) as Map<String, dynamic>;

      final latest = _extractLatestVersion(json);
      if (latest == null) {
        return UpdateCheckResult(
          currentVersion: currentVersion,
          updateAvailable: false,
          message: 'Could not parse latest version from pub.dev response.',
        );
      }

      final available = _isNewer(currentVersion, latest);
      final msg = available
          ? 'Update available: $currentVersion → $latest'
          : 'Already on the latest version.';

      return UpdateCheckResult(
        currentVersion: currentVersion,
        latestVersion: latest,
        updateAvailable: available,
        message: msg,
      );
    } on SocketException {
      return UpdateCheckResult(
        currentVersion: currentVersion,
        updateAvailable: false,
        message: 'Network error: Could not reach $apiBaseUrl. '
            'Check your internet connection.',
      );
    } on FormatException catch (e) {
      return UpdateCheckResult(
        currentVersion: currentVersion,
        updateAvailable: false,
        message: 'Failed to parse pub.dev response: $e',
      );
    } catch (e) {
      return UpdateCheckResult(
        currentVersion: currentVersion,
        updateAvailable: false,
        message: 'Unexpected error checking for update: $e',
      );
    }
  }

  /// Synchronous version of checkForUpdate for unit testing version
  /// comparison logic directly from a JSON map.
  ///
  /// Not intended for production use — only for tests.
  UpdateCheckResult checkForUpdateSync({
    required Map<String, dynamic> pubDevResponse,
  }) {
    final latest = _extractLatestVersion(pubDevResponse);
    if (latest == null) {
      return UpdateCheckResult(
        currentVersion: currentVersion,
        updateAvailable: false,
        message: 'Could not parse latest version.',
      );
    }
    return UpdateCheckResult(
      currentVersion: currentVersion,
      latestVersion: latest,
      updateAvailable: _isNewer(currentVersion, latest),
      message: _isNewer(currentVersion, latest)
          ? 'Update available: $currentVersion → $latest'
          : 'Already on the latest version.',
    );
  }

  /// Perform the self-update by running `dart pub global activate`.
  Future<UpdateResult> performUpdate() async {
    try {
      final result = await _runProcess('dart', [
        'pub',
        'global',
        'activate',
        packageName,
      ]);

      if (result.exitCode == 0) {
        return UpdateResult(
          success: true,
          message: 'Successfully updated $packageName. '
              'Run `zorphy_cli --version` to verify.',
        );
      } else {
        return UpdateResult(
          success: false,
          exitCode: result.exitCode,
          message: '`dart pub global activate $packageName` failed.\n'
              '${result.stderr}',
        );
      }
    } catch (e) {
      return UpdateResult(
        success: false,
        message: 'Failed to run update command: $e',
      );
    }
  }

  /// Perform the update and verify the new version.
  Future<UpdateResult> performUpdateAndVerify() async {
    final updateResult = await performUpdate();
    if (!updateResult.success) return updateResult;

    // Verify by running zorphy_cli --version
    try {
      final verifyResult = await _runProcess('zorphy_cli', ['--version']);
      if (verifyResult.exitCode == 0) {
        final newVersion = verifyResult.stdout.toString().trim();
        return UpdateResult(
          success: true,
          newVersion: newVersion,
          message: 'Updated and verified. Running version: $newVersion',
        );
      } else {
        return UpdateResult(
          success: true,
          message: 'Update applied but version verification failed. '
              'Run `zorphy_cli --version` to check manually.',
        );
      }
    } catch (e) {
      return UpdateResult(
        success: true,
        message: 'Update applied but could not verify. '
            'Run `zorphy_cli --version` to check.',
      );
    }
  }

  /// Extract the latest stable version from the pub.dev API response JSON.
  String? _extractLatestVersion(Map<String, dynamic> json) {
    // Try the 'latest' field first
    String? latestVersion;
    try {
      final latest = json['latest'] as Map<String, dynamic>?;
      if (latest != null) {
        latestVersion = latest['version'] as String?;
        if (latestVersion != null && latestVersion.isNotEmpty) {
          return latestVersion;
        }
      }
    } catch (_) {}

    // Fallback: scan versions list for highest version
    try {
      final versions = json['versions'] as List<dynamic>?;
      if (versions != null && versions.isNotEmpty) {
        final allVersions = <String>[];
        for (final v in versions) {
          if (v is Map<String, dynamic>) {
            final version = v['version'] as String?;
            if (version != null && version.isNotEmpty) {
              allVersions.add(version);
            }
          }
        }

        if (allVersions.isEmpty) return null;

        // Separate stable and prerelease versions
        final stableVersions = allVersions
            .where((v) => !v.contains('-') && !v.contains('+'))
            .toList();
        final prereleaseVersions = allVersions
            .where((v) => v.contains('-') || v.contains('+'))
            .toList();

        // Select highest stable version, or highest prerelease if no stable
        final candidateVersions = stableVersions.isNotEmpty
            ? stableVersions
            : prereleaseVersions;

        if (candidateVersions.isEmpty) return null;

        // Find the highest version using existing comparison
        String highest = candidateVersions.first;
        for (final version in candidateVersions.skip(1)) {
          if (_isNewer(highest, version)) {
            highest = version;
          }
        }
        return highest;
      }
    } catch (_) {}

    return null;
  }

  /// Compare two semantic versions. Returns true if [latest] is newer
  /// than [current].
  bool _isNewer(String current, String latest) {
    final currentParts = _parseVersion(current);
    final latestParts = _parseVersion(latest);

    if (currentParts == null || latestParts == null) {
      return current != latest;
    }

    for (var i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false; // equal
  }

  /// Parse "2.0.0" or "v2.0.0-beta.1" into [2, 0, 0].
  List<int>? _parseVersion(String version) {
    final clean = version
        .replaceFirst(RegExp(r'^v'), '')
        .split('-')
        .first
        .split('+')
        .first;
    final parts = clean.split('.').map((s) => int.tryParse(s)).toList();
    return parts.every((p) => p != null) ? parts.cast<int>() : null;
  }

  /// Fetch JSON from a URL.
  Future<String> _doFetchJson(String url) async {
    if (fetchJson != null) {
      return fetchJson!(url, timeout: const Duration(seconds: 10));
    }

    // Default: real HTTP fetch with overall timeout
    final uri = Uri.parse(url);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await Future.value(null).timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          throw TimeoutException('HTTP request timed out after 10 seconds');
        },
      ).then((_) async {
        final request = await client.getUrl(uri);
        request.headers.set('User-Agent',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.0');
        request.headers.set('Accept', 'application/json');
        final response = await request.close();

        if (response.statusCode != 200) {
          throw HttpException(
            'pub.dev API returned status ${response.statusCode}',
            uri: uri,
          );
        }

        return await response.transform(utf8.decoder).join();
      });
    } finally {
      client.close(force: true);
    }
  }

  /// Run a subprocess.
  Future<ProcessResult> _runProcess(String executable, List<String> args) async {
    if (processRunner != null) {
      return processRunner!(executable, args);
    }

    return Process.run(
      executable,
      args,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  }
}
