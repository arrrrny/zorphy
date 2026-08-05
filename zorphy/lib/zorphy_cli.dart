/// CLI entry point - only imports what's needed for entity creation
/// This avoids pulling in heavy dependencies like analyzer, source_gen, etc.
library zorphy_cli_entry;

export 'src/cli/entity_creator.dart';
export 'src/cli/models/entity_config.dart';
export 'src/cli/models/update_result.dart';
export 'src/cli/models/validation_result.dart';
export 'src/cli/services/project_validator.dart';
export 'src/cli/services/version_checker.dart';
export 'src/cli/utils/naming_utils.dart';
