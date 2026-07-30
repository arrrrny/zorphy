import 'package:build/build.dart';

import 'builder.dart';

/// Deprecated alias for [zorphyBuilder].
///
/// Since zorphy 2.0 there is a single unified, single-pass generator that
/// handles both `@Zorphy` and `@Zorphy2` annotations and resolves
/// polymorphic ordering internally. This factory remains so existing
/// `build.yaml` references keep working; it returns the same builder as
/// [zorphyBuilder]. Will be removed in a later major release.
@Deprecated('Use zorphyBuilder instead. Identical since zorphy 2.0; '
    'will be removed in a later major release.')
Builder zorphy2Builder(BuilderOptions options) => zorphyBuilder(options);
