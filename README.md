# ONIS Viewer - Flutter + FFI + C++

This project is a reimplementation of ONIS Viewer using Flutter with FFI integration for native C++ code.

## Project Structure

```
onis_viewer/
├── lib/
│   ├── main.dart              # Main Flutter application
│   └── ffi/
│       └── onis_ffi.dart      # FFI Dart <-> C++ bindings
├── native/
│   ├── onis_core.h            # Native C++ headers
│   └── onis_core.cpp          # Native C++ implementation
├── windows/                   # Windows configuration
├── macos/                     # macOS configuration
├── linux/                     # Linux configuration
├── android/                   # Android configuration
└── ios/                       # iOS configuration
```

## Current Features

- ✅ Flutter <-> C++ FFI integration
- ✅ Test of simple C++ functions (version, name, addition)
- ✅ Modern Flutter user interface
- ✅ Multi-platform support (desktop + mobile)

## Planned Features

- 🔄 DICOM loading and visualization
- 🔄 Image streaming
- 🔄 Interactive annotations
- 🔄 Hanging protocols
- 🔄 Editing module
- 🔄 Multi-source support
- 🔄 OpenGL acceleration

## Build and Run

### Prerequisites

- Flutter SDK (latest stable version)
- CMake (for C++ compilation)
- C++ compiler (Visual Studio on Windows, Xcode on macOS, GCC on Linux)

### Build

```bash
# In the project directory
flutter pub get
flutter build windows  # or macos, linux, android, ios
```

### Run

```bash
flutter run -d windows  # or macos, linux, android, ios
```

## FFI Architecture

The project uses FFI (Foreign Function Interface) to call C++ code from Flutter:

1. **Native C++ code** (`native/`) : Contains critical functions (DICOM processing, acceleration, etc.)
2. **FFI bindings** (`lib/ffi/`) : Dart interface to call C++ functions
3. **Flutter application** (`lib/`) : User interface and business logic

### FFI Usage Example

```dart
// Initialization
OnisCore.initialize();

// Call C++ functions
String version = OnisCore.getVersion();
String name = OnisCore.getName();
int result = OnisCore.add(5, 3);
```

## Development

### Adding a new C++ function

1. Declare the function in `native/onis_core.h`
2. Implement in `native/onis_core.cpp`
3. Add the binding in `lib/ffi/onis_ffi.dart`
4. Use in the Flutter application

### Multi-platform support

- **Desktop** : Direct compilation via CMake
- **Mobile** : Integration via NDK (Android) and Xcode (iOS)

### Quality Assurance

The project includes a comprehensive quality infrastructure in the `.infra/` folder:

```bash
# Install development environment
./.infra/setup-dev-environment.sh

# Install Git hooks
./.infra/install-git-hooks.sh

# Run quality checks
./.infra/quality-check.sh
```

See `.infra/README.md` for detailed quality guidelines and `QUALITY_SUMMARY.md` for a complete overview.

## License

© 2024 - Based on original ONIS Viewer
