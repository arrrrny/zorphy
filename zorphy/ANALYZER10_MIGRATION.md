# Analyzer 10 / Source Gen 4.x Migration Guide

## Overview
Migration of Zorphy from analyzer 7 APIs to analyzer 10 + source_gen 4.x APIs.

## Breaking API Changes

### TypeChecker Changes
| Old API (analyzer 6.x / source_gen 1.x) | New API (analyzer 10.x / source_gen 4.x) |
|------------------------------------------|----------------------------------------|
| `TypeChecker.fromRuntime(Type)` | `TypeChecker.typeNamed(Type)` |
| `TypeChecker.fromType(Type)` | `TypeChecker.typeNamed(Type)` |
| `TypeChecker.fromUrl(String)` | `TypeChecker.fromUrl(String)` (unchanged) |

**Example:**
```dart
// OLD (doesn't work in analyzer 10)
TypeChecker get typeChecker => TypeChecker.fromRuntime(Zorphy);

// NEW (works in analyzer 10)
TypeChecker get typeChecker => TypeChecker.typeNamed(Zorphy);
```

### Metadata Changes (CRITICAL)
| Old API (analyzer 6.x) | New API (analyzer 10.x) |
|-------------------------|------------------------|
| `element.metadata` returned `List<Metadata>` | `element.metadata` returns single `Metadata` object |
| Iterate: `for (var m in element.metadata)` | Iterate: `for (var m in element.metadata.annotations)` |
| N/A | Access annotation element: `element.metadata.annotations` returns `List<ElementAnnotation>` |

**Example:**
```dart
// OLD (analyzer 6.x)
for (var annotation in field.metadata) {
  var element = annotation.element;
}

// NEW (analyzer 10.x)
for (var annotation in field.metadata.annotations) {
  var element = annotation.element;
}
```

### ClassElement Name Property
| Old API | New API |
|---------|---------|
| `ClassElement.name3` | `ClassElement.name` |

### LibraryElement Changes
| Old API | New API |
|---------|---------|
| `LibraryElement.source` | Removed - use `LibraryElement.definingCompilationUnit.source` |
| `LibraryElement.definingCompilationUnit` | Still available |
| `LibraryElement.importedLibraries` | Still available |

### ConstructorElement Changes
| Old API | New API |
|---------|---------|
| `ConstructorElement.parameters` | Still available, but may need `.declaredParameters` |

### Element Display Name
| Old API | New API |
|---------|---------|
| `element.displayName` | `element.name` |

## Files Affected
1. `lib/src/ZorphyGenerator.dart` - TypeChecker, LibraryElement, ClassElement
2. `lib/src/common/helpers.dart` - Metadata → ElementAnnotation
3. `lib/src/common/GeneratorForAnnotationX.dart` - TypeChecker base class

## Verification Commands
```bash
dart analyze lib/
dart pub get
```
