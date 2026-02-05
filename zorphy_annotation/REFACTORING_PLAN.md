## Zorphy Annotation Refactoring Plan

### Current Issues
1. **Mixed Concerns**: `zorphy.dart` contains annotations, constants, AND utility functions
2. **Poor Organization**: No clear separation between different types of functionality
3. **Naming**: `List_E` is not descriptive
4. **Documentation**: Limited inline documentation

### Target Structure
```
zorphy_annotation/lib/src/
├── annotations/              # Annotation definitions
│   ├── zorphy.dart           # @Zorphy annotation class
│   ├── zorphy2.dart          # @Zorphy2 annotation class
│   └── zorphy_x.dart         # ZorphyX interface
│
├── core/                     # Core abstractions
│   ├── patch.dart            # Patch<T> interface
│   ├── patch_base.dart       # PatchBase<T> abstract class
│   └── enhanced_list.dart    # EnhancedList (renamed from List_E)
│
├── types/                    # Special types
│   └── optional.dart         # Opt<T> optional wrapper
│
├── utils/                    # Utility functions
│   └── generic_serialization.dart  # Generic JSON helpers
│
└── zorphy_annotation.dart    # Main export file
```

### Benefits
- Clear separation of concerns
- Better discoverability
- Improved documentation
- Consistent naming
- Easier to maintain
