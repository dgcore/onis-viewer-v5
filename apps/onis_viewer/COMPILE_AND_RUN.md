# How to Compile and Run ONIS Viewer

## 🚀 Quick Start Guide

### Prerequisites
- Flutter SDK (3.27.2 or later)
- Dart SDK
- Xcode (for macOS)
- CMake (for native C++ compilation)
- clang-format (for code formatting)

## 📱 Development Mode (Recommended)

### 1. **Setup Development Environment**
```bash
# Clone the repository
git clone <repository-url>
cd onis_viewer

# Install development environment
./.infra/setup-dev-environment.sh

# Install Git hooks
./.infra/install-git-hooks.sh
```

### 2. **Compile Native C++ Code**
```bash
# For macOS
cd macos && ./build_native.sh && cd ..

# For Windows (when implemented)
# cd windows && ./build_native.bat && cd ..

# For Linux (when implemented)
# cd linux && ./build_native.sh && cd ..
```

### 3. **Run the Application**

#### macOS
```bash
# Run in debug mode
flutter run -d macos

# Run in release mode
flutter run -d macos --release

# Run with specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

#### Windows
```bash
flutter run -d windows
```

#### Linux
```bash
flutter run -d linux
```

#### Web
```bash
flutter run -d chrome
```

## 🔨 Build for Production

### 1. **Complete Build Process**
```bash
# Use the automated build script
./build_all.sh
```

### 2. **Manual Build Steps**

#### macOS
```bash
# Build native C++ library
cd macos && ./build_native.sh && cd ..

# Build Flutter app
flutter build macos --release

# The app will be in: build/macos/Build/Products/Release/onis_viewer.app
```

#### Windows
```bash
# Build native C++ library (when implemented)
cd windows && ./build_native.bat && cd ..

# Build Flutter app
flutter build windows --release

# The app will be in: build/windows/runner/Release/
```

#### Linux
```bash
# Build native C++ library (when implemented)
cd linux && ./build_native.sh && cd ..

# Build Flutter app
flutter build linux --release

# The app will be in: build/linux/x64/release/bundle/
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. **"Failed to load dynamic library" Error**
```bash
# Solution: Rebuild the native C++ library
cd macos && ./build_native.sh && cd ..
cp macos/build_native/libonis_core.dylib build/macos/Build/Products/Debug/onis_viewer.app/Contents/MacOS/
```

#### 2. **Flutter Doctor Issues**
```bash
# Check Flutter installation
flutter doctor

# Fix common issues
flutter doctor --android-licenses  # For Android
sudo xcode-select --install        # For Xcode on macOS
```

#### 3. **Build Failures**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d macos
```

#### 4. **Native Library Not Found**
```bash
# Verify library location
ls -la build/macos/Build/Products/Debug/onis_viewer.app/Contents/MacOS/

# Rebuild if missing
cd macos && ./build_native.sh && cd ..
```

## 📋 Development Workflow

### Daily Development
```bash
# 1. Start development
flutter run -d macos

# 2. Make changes to code
# 3. Hot reload (press 'r' in terminal)
# 4. Test changes
# 5. Commit with quality checks
git add .
git commit -m "feat: add new feature"
```

### Quality Assurance
```bash
# Run quality checks
./.infra/quality-check.sh

# Format code
dart format .
clang-format -i native/*.cpp native/*.h

# Run tests
flutter test
```

## 🎯 Platform-Specific Instructions

### macOS
```bash
# Prerequisites
brew install cmake clang-format

# Build and run
cd macos && ./build_native.sh && cd ..
flutter run -d macos
```

### Windows
```bash
# Prerequisites
# Install Visual Studio with C++ support
# Install CMake

# Build and run (when implemented)
cd windows && ./build_native.bat && cd ..
flutter run -d windows
```

### Linux
```bash
# Prerequisites
sudo apt-get install cmake clang-format

# Build and run (when implemented)
cd linux && ./build_native.sh && cd ..
flutter run -d linux
```

## 🔧 Advanced Configuration

### Debug Mode
```bash
# Run with debug information
flutter run -d macos --debug

# Enable verbose logging
flutter run -d macos --verbose
```

### Profile Mode
```bash
# Run with profiling
flutter run -d macos --profile
```

### Release Mode
```bash
# Run optimized version
flutter run -d macos --release
```

### Custom Build Configuration
```bash
# Build with specific configuration
flutter build macos --release --dart-define=ENVIRONMENT=production
```

## 📊 Performance Monitoring

### Build Performance
```bash
# Measure build time
time flutter build macos --release

# Profile build process
flutter build macos --profile --analyze-size
```

### Runtime Performance
```bash
# Run with performance overlay
flutter run -d macos --enable-software-rendering

# Profile memory usage
flutter run -d macos --trace-startup
```

## 🚀 Deployment

### Create Installer (macOS)
```bash
# Build release version
flutter build macos --release

# Create DMG (requires additional tools)
# The app is ready in: build/macos/Build/Products/Release/onis_viewer.app
```

### Create Installer (Windows)
```bash
# Build release version
flutter build windows --release

# Create installer (requires additional tools)
# The app is ready in: build/windows/runner/Release/
```

### Create Installer (Linux)
```bash
# Build release version
flutter build linux --release

# Create AppImage or package
# The app is ready in: build/linux/x64/release/bundle/
```

## 📞 Support

### Getting Help
- Check `README.md` for project overview
- Review `DEVELOPMENT.md` for development guidelines
- Run `./.infra/quality-check.sh` for diagnostics
- Check Flutter documentation: https://flutter.dev/docs

### Common Commands Reference
```bash
# Development
flutter run -d macos          # Run app
flutter test                  # Run tests
flutter clean                 # Clean build
flutter pub get              # Get dependencies

# Quality
./.infra/quality-check.sh    # Quality verification
dart format .                # Format Dart code
clang-format -i native/*.cpp # Format C++ code

# Build
./build_all.sh               # Complete build
flutter build macos          # Build for macOS
```

---

**Note**: This guide covers the complete compilation and running process for ONIS Viewer. The native C++ library must be compiled before running the Flutter app for FFI functionality to work properly. 