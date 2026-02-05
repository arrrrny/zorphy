import '../common/NameType.dart';
import '../common/classes.dart';

/// Re-exports Interface for backward compatibility
export '../common/classes.dart' show Interface;

/// Re-exports existing NameTypeClassComment for backward compatibility
/// This will be replaced with a proper FieldMetadata in future iterations
typedef FieldMetadata = NameTypeClassComment;
