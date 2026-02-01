# ONIS5 - Multi-Application Medical Imaging Platform

ONIS5 is a comprehensive medical imaging platform that includes multiple applications sharing common C++ libraries and code.

## 🏗️ Project Structure

```
ONIS5/
├── apps/                      # Applications
│   ├── onis_viewer/           # Flutter-based medical image viewer
│   │   ├── lib/               # Dart source code
│   │   ├── macos/             # macOS native code and build
│   │   └── build/             # Flutter build output
│   └── onis_site_server/      # C++ HTTP server application
│       ├── src/               # C++ source files
│       ├── include/           # Header files
│       └── build.sh           # Build script
├── libs/                      # Shared C++ libraries
│   └── onis_kit/             # ONIS toolkit library (database, utilities)
├── shared/                    # Shared code between applications
│   └── cpp/                   # Shared C++ code
│       └── onis_core/         # Core ONIS functionality
├── build/                     # Unified C++/CMake build directory (root)
│   ├── bin/                   # Executables (onis_site_server)
│   └── lib/                   # Libraries (libonis_core, libonis_kit)
├── scripts/                   # Build and utility scripts
│   ├── build_all.sh          # Build all components
│   └── format_code.sh        # Code formatting
└── .infra/                    # Quality infrastructure
    ├── quality-check.sh       # Quality verification
    └── pre-commit-hooks.sh    # Git hooks
```

## 🚀 Applications

### ONIS Viewer (Flutter)
- **Location**: `apps/onis_viewer/`
- **Type**: Cross-platform Flutter application
- **Purpose**: Medical image viewing and analysis
- **Platforms**: Desktop (Windows, macOS, Linux), Mobile (iOS, Android)
- **Technologies**: Flutter, Dart, FFI for native C++ integration

### ONIS Site Server (C++)
- **Location**: `apps/onis_site_server/`
- **Type**: C++ HTTP server application
- **Purpose**: Backend services for medical imaging, database management, authentication
- **Platforms**: macOS, Linux, Windows
- **Technologies**: 
  - Drogon (HTTP framework)
  - JsonCPP (JSON processing)
  - jwt-cpp (JWT authentication)
  - OpenSSL (cryptography)
  - PostgreSQL/SQLite (database)

## 📚 Shared Libraries

### ONIS Kit (`libs/onis_kit/`)
- Database abstraction layer (PostgreSQL, SQLite)
- Core utilities and types
- Result handling

### ONIS Core (`shared/cpp/onis_core/`)
- Core ONIS functionality
- Shared between applications

## 🛠️ Development

### Prerequisites
- **Flutter SDK** (3.6.1+)
- **C++ compiler** (Clang/GCC with C++17 support)
- **CMake** 3.20+
- **Drogon** (HTTP framework, via Homebrew on macOS)
- **JsonCPP** (via Homebrew on macOS)
- **OpenSSL** (via Homebrew on macOS)
- **PostgreSQL** or **SQLite** (for database)

### Building the Project

#### Unified Build (Recommended)
Build all C++ components from the root:
```bash
# From project root
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(sysctl -n hw.ncpu)  # macOS
# or
make -j$(nproc)              # Linux
```

Outputs:
- **Server**: `build/bin/onis_site_server`
- **Libraries**: `build/lib/libonis_core.*`, `build/lib/libonis_kit.*`

#### Build Individual Components

**ONIS Site Server:**
```bash
# Option 1: Use the build script
cd apps/onis_site_server
./build.sh

# Option 2: Use unified build (recommended)
# From project root
cd build
make onis_site_server
```

**ONIS Viewer (Flutter):**
```bash
cd apps/onis_viewer
flutter pub get
flutter build macos --scheme Runner  # macOS
# or
flutter build windows                # Windows
flutter build linux                  # Linux
```

**Build All (Script):**
```bash
./scripts/build_all.sh
```

### Running Applications

**ONIS Site Server:**
```bash
./build/bin/onis_site_server
```

**ONIS Viewer:**
```bash
cd apps/onis_viewer
flutter run -d macos --scheme Runner
```

## 🧪 Quality Assurance

The project includes comprehensive quality infrastructure in `.infra/`:

### Automated Checks
- **Code Formatting**: Dart (`dart format`) and C++ (`clang-format`)
- **Static Analysis**: Dart (`flutter analyze`) and C++ (can be extended with clang-tidy)
- **Tests**: Flutter tests
- **Compilation**: Automatic build verification

### Git Hooks
Pre-commit and pre-push hooks automatically run quality checks:
```bash
# Install hooks
./.infra/install-git-hooks.sh
```

### Manual Quality Check
```bash
./.infra/quality-check.sh
```

## 📖 Documentation

- [Quality Infrastructure](.infra/README.md) - Code quality tools and standards
- [Formatting Guide](scripts/README_FORMATTING.md) - Code formatting guidelines

## 🔧 Build Directory Structure

The project uses a unified build structure:

- **C++/CMake builds**: `build/` at project root
  - All executables: `build/bin/`
  - All libraries: `build/lib/`
  
- **Flutter builds**: `apps/onis_viewer/build/`
  - Platform-specific builds (macos, windows, linux, etc.)
  
- **Native Flutter code**: `apps/onis_viewer/macos/build_native/`
  - C++ code compiled for Flutter FFI

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/new-feature`
2. Make your changes
3. Run quality checks: `./.infra/quality-check.sh`
4. Commit with conventional commits: `git commit -m "feat: add new feature"`
5. Create a Pull Request

### Code Style
- **Dart**: Follow Flutter style guide, use `dart format`
- **C++**: Follow Google C++ style, use `clang-format`
- **Formatting**: Run `./scripts/format_code.sh` before committing

## 📄 License

[Add your license information here]

## 🔗 Links

- [Quality Infrastructure](.infra/README.md)
- [Formatting Guide](scripts/README_FORMATTING.md)
