import 'package:code_builder/code_builder.dart';

/// A [Spec] marker that signals the orchestrator to inject
/// code into the primary class body rather than at the library level.
///
/// Two modes:
/// - If [constructor] is non-null, it is added to the class's
///   constructors list (for factory constructors like fromJson).
/// - If [method] is non-null, it is added to the class's methods.
class ClassMemberCode implements Spec {
  /// A constructor to inject into the class.
  final Constructor? constructor;

  /// A method to inject into the class.
  final Method? method;

  /// Creates a [ClassMemberCode] wrapping a [Constructor].
  const ClassMemberCode.constructor(this.constructor) : method = null;

  /// Creates a [ClassMemberCode] wrapping a [Method].
  const ClassMemberCode.method(this.method) : constructor = null;

  @override
  R accept<R>(covariant SpecVisitor<R> visitor, [R? context]) {
    // This is never called directly by the emitter — the orchestrator
    // unwraps it before building the Library.
    throw UnsupportedError(
      'ClassMemberCode should be unwrapped by the orchestrator',
    );
  }
}
