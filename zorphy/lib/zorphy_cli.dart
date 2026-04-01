/// CLI entry point - only imports what's needed for entity creation
/// This avoids pulling in heavy dependencies like analyzer, source_gen, etc.
library zorphy_cli_entry;

export 'src/cli/entity_creator.dart';
export 'src/cli/models/entity_config.dart';
export 'src/cli/utils/naming_utils.dart';
