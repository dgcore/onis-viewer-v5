# ONIS5 - Multi-Application Medical Imaging Platform

ONIS5 is a comprehensive medical imaging platform that includes multiple applications sharing common C++ libraries and code.

## 🏗️ Project Structure

```
ONIS5/
├── apps/                      # Applications
│   ├── onis_viewer/           # Flutter-based medical image viewer
│   └── onis_site_server/      # C++ server application (planned)
├── libs/                      # External C++ libraries
│   ├── dcmtk/                 # DICOM toolkit
│   ├── boost/                 # Boost libraries
│   ├── onis_core/             # ONIS core library
│   └── cmake/                 # CMake configurations
├── shared/                    # Shared code between applications
│   ├── cpp/                   # Shared C++ code
│   │   ├── onis_core/         # Core ONIS functionality
│   │   ├── dicom/             # DICOM processing
│   │   └── utils/             # Utility functions
│   └── proto/                 # Protocol buffers (if needed)
├── docs/                      # Documentation
├── scripts/                   # Build and utility scripts
└── .infra/                    # Quality infrastructure
```

## 🚀 Applications

### ONIS Viewer (Flutter)
- **Location**: `apps/onis_viewer/`
- **Type**: Cross-platform Flutter application
- **Purpose**: Medical image viewing and analysis
- **Platforms**: Desktop (Windows, macOS, Linux), Mobile (iOS, Android)

### ONIS Site Server (C++)
- **Location**: `apps/onis_site_server/` (planned)
- **Type**: C++ server application
- **Purpose**: Backend services for medical imaging
- **Platforms**: Linux, Windows Server

## 📚 Shared Libraries

### External Libraries
- **DCMTK**: DICOM toolkit for medical image processing
- **Boost**: C++ utility libraries
- **ONIS Core**: Custom core functionality

### Shared Code
- **ONIS Core**: Common C++ functionality used by all applications
- **DICOM Processing**: Shared DICOM handling code
- **Utilities**: Common utility functions

## 🛠️ Development

### Prerequisites
- Flutter SDK
- C++ compiler (GCC, Clang, MSVC)
- CMake 3.20+
- Git

### Building Applications

#### ONIS Viewer (Flutter)
```bash
cd apps/onis_viewer
flutter pub get
flutter build macos  # or windows, linux, ios, android
```

#### ONIS Site Server (C++)
```bash
cd apps/onis_site_server
mkdir build && cd build
cmake ..
make
```

### Quality Assurance
The project includes comprehensive quality infrastructure in `.infra/`:
- Automated code formatting
- Static analysis
- Unit testing
- Git hooks for quality enforcement

## 📖 Documentation

- [Development Guide](apps/onis_viewer/DEVELOPMENT.md)
- [Quality Infrastructure](.infra/README.md)
- [Build Instructions](apps/onis_viewer/COMPILE_AND_RUN.md)

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/new-feature`
2. Make your changes
3. Run quality checks: `./.infra/quality-check.sh`
4. Commit with conventional commits: `git commit -m "feat: add new feature"`
5. Create a Pull Request

## 📄 License

[Add your license information here]

## 🔗 Links

- [ONIS Viewer Documentation](apps/onis_viewer/README.md)
- [Quality Infrastructure](.infra/README.md)
- [Development Guide](apps/onis_viewer/DEVELOPMENT.md) 