# Debugging ONIS Viewer in the IDE

## 🚀 Yes! You Can Debug Directly in VS Code

ONIS Viewer is fully configured for debugging within VS Code. Here's how to set it up and use it effectively.

## 📋 Prerequisites

### Required Extensions
Make sure you have these VS Code extensions installed:
- **Dart Code** (Dart and Flutter support)
- **Flutter** (Flutter framework support)
- **C/C++** (C++ debugging support)
- **CMake Tools** (CMake integration)
- **EditorConfig** (Editor consistency)

### Automatic Installation
The project includes automatic extension recommendations in `.vscode/extensions.json`. VS Code should prompt you to install them when you open the project.

## 🔧 Setup for Debugging

### 1. **Build Native C++ Library First**
```bash
# This is required for FFI to work
cd macos && ./build_native.sh && cd ..
```

### 2. **Open Project in VS Code**
```bash
code .  # Opens the project in VS Code
```

### 3. **Verify Configuration**
- Check that the `.vscode/` folder is present
- Ensure all recommended extensions are installed
- Verify Flutter SDK is detected

## 🎯 Debugging Configurations

### Available Debug Configurations

The project includes 5 pre-configured debug configurations:

#### 1. **ONIS Viewer (macOS) - Debug Mode**
- **Purpose**: Development and debugging
- **Features**: Hot reload, breakpoints, variable inspection
- **Best for**: Daily development

#### 2. **ONIS Viewer (Profile) - Profile Mode**
- **Purpose**: Performance profiling
- **Features**: Performance metrics, memory analysis
- **Best for**: Performance optimization

#### 3. **ONIS Viewer (Release) - Release Mode**
- **Purpose**: Production-like testing
- **Features**: Optimized performance, no debug symbols
- **Best for**: Final testing before release

#### 4. **Flutter Tests**
- **Purpose**: Running and debugging tests
- **Features**: Test debugging, step-through test execution
- **Best for**: Test development and debugging

#### 5. **Current File**
- **Purpose**: Debug the currently open file
- **Features**: Quick debugging of specific files
- **Best for**: Isolated debugging

## 🚀 How to Start Debugging

### Method 1: Using Debug Panel
1. **Open Debug Panel**: `Ctrl+Shift+D` (Windows/Linux) or `Cmd+Shift+D` (macOS)
2. **Select Configuration**: Choose "ONIS Viewer (macOS)" from dropdown
3. **Click Play Button**: Or press `F5` to start debugging

### Method 2: Using Command Palette
1. **Open Command Palette**: `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (macOS)
2. **Type**: "Debug: Start Debugging"
3. **Select**: "ONIS Viewer (macOS)"

### Method 3: Using Terminal
```bash
# Start debugging from terminal
flutter run -d macos --debug
```

## 🔍 Debugging Features

### Breakpoints
- **Set Breakpoints**: Click in the gutter next to line numbers
- **Conditional Breakpoints**: Right-click breakpoint → Edit Breakpoint
- **Logpoints**: Right-click breakpoint → Add Logpoint

### Variable Inspection
- **Variables Panel**: View local variables, parameters, and fields
- **Watch Panel**: Add expressions to monitor
- **Call Stack**: Navigate through function calls

### Hot Reload
- **Hot Reload**: `Ctrl+F5` (Windows/Linux) or `Cmd+F5` (macOS)
- **Hot Restart**: `Ctrl+Shift+F5` (Windows/Linux) or `Cmd+Shift+F5` (macOS)

### Debug Console
- **Evaluate Expressions**: Type Dart expressions in debug console
- **Print Variables**: Use `print()` statements
- **Inspect Objects**: Use `debugPrint()` for detailed output

## 🛠️ Debugging FFI Code

### Dart FFI Debugging
```dart
// Add breakpoints in Dart FFI code
class OnisCore {
  static String getVersion() {
    // Set breakpoint here
    if (!_initialized) initialize();
    final ptr = _onisGetVersion();  // Set breakpoint here
    return _ptrToString(ptr);       // Set breakpoint here
  }
}
```

### C++ Debugging
```cpp
// Add breakpoints in C++ code
const char* onis_get_version() {
    // Set breakpoint here
    return VERSION;  // Set breakpoint here
}
```

### Mixed Debugging Setup
1. **Dart Debugging**: Use VS Code's built-in Dart debugger
2. **C++ Debugging**: Use LLDB or GDB for native code
3. **FFI Bridge**: Debug the interface between Dart and C++

## 📋 Debugging Workflow

### 1. **Setup Debug Session**
```bash
# 1. Build native library
cd macos && ./build_native.sh && cd ..

# 2. Open VS Code
code .

# 3. Set breakpoints in code
# 4. Start debugging (F5)
```

### 2. **Debug Session**
- **Set Breakpoints**: In Dart and C++ code
- **Start Debugging**: F5 or Debug panel
- **Step Through Code**: F10 (step over), F11 (step into), Shift+F11 (step out)
- **Inspect Variables**: Use Variables panel
- **Hot Reload**: Make changes and reload

### 3. **Advanced Debugging**
- **Conditional Breakpoints**: Set conditions for breakpoints
- **Watch Expressions**: Monitor specific variables
- **Call Stack Navigation**: Navigate through function calls
- **Exception Handling**: Catch and debug exceptions

## 🔧 Debugging Tasks

### Available Tasks (Ctrl+Shift+P → "Tasks: Run Task")

#### Quality Tasks
- **Quality Check**: Run complete quality verification
- **Format Dart**: Format Dart code
- **Format C++**: Format C++ code
- **Analyze Dart**: Run static analysis

#### Build Tasks
- **Build macOS**: Complete build process
- **Clean Build**: Clean and rebuild
- **Get Dependencies**: Update dependencies

#### Test Tasks
- **Run Tests**: Execute test suite

## 🎯 Debugging Tips

### 1. **FFI Debugging**
```dart
// Add debug prints for FFI calls
static String getVersion() {
  print('DEBUG: Initializing FFI...');
  if (!_initialized) initialize();
  print('DEBUG: Calling C++ function...');
  final ptr = _onisGetVersion();
  print('DEBUG: Converting pointer to string...');
  return _ptrToString(ptr);
}
```

### 2. **Error Handling**
```dart
// Add try-catch for FFI errors
try {
  final version = OnisCore.getVersion();
  print('Version: $version');
} catch (e) {
  print('FFI Error: $e');
  // Set breakpoint here to debug
}
```

### 3. **Performance Debugging**
```dart
// Use profile mode for performance issues
// Select "ONIS Viewer (Profile)" configuration
// Monitor CPU and memory usage
```

## 🚨 Troubleshooting

### Common Issues

#### 1. **"Failed to load dynamic library"**
```bash
# Solution: Rebuild native library
cd macos && ./build_native.sh && cd ..
```

#### 2. **Breakpoints Not Hit**
- Ensure you're running in debug mode
- Check that the correct configuration is selected
- Verify the code path is being executed

#### 3. **Hot Reload Not Working**
- Check for syntax errors
- Ensure the app is running in debug mode
- Try hot restart instead

#### 4. **C++ Breakpoints Not Working**
- Ensure C++ extension is installed
- Check that C++ code is compiled with debug symbols
- Use LLDB for C++ debugging

## 📊 Debugging Tools

### Built-in Tools
- **Debug Console**: Evaluate expressions
- **Variables Panel**: Inspect variables
- **Watch Panel**: Monitor expressions
- **Call Stack**: Navigate function calls
- **Breakpoints Panel**: Manage breakpoints

### External Tools
- **Flutter Inspector**: Widget debugging
- **DevTools**: Performance profiling
- **LLDB**: C++ debugging
- **Chrome DevTools**: Web debugging

## 🎯 Best Practices

### 1. **Organize Breakpoints**
- Use meaningful names for breakpoints
- Group related breakpoints
- Use conditional breakpoints for specific scenarios

### 2. **Debugging Strategy**
- Start with high-level breakpoints
- Drill down to specific functions
- Use logging for continuous monitoring
- Profile performance bottlenecks

### 3. **Code Organization**
- Keep debug code separate from production code
- Use debug flags for conditional compilation
- Clean up debug statements before committing

## 📞 Support

### Getting Help
- Check VS Code documentation
- Review Flutter debugging guide
- Use Flutter DevTools for advanced debugging
- Check project documentation

### Useful Commands
```bash
# Debug from terminal
flutter run -d macos --debug

# Open DevTools
flutter run -d macos --debug --enable-software-rendering

# Profile mode
flutter run -d macos --profile
```

---

**Note**: The IDE debugging setup is fully configured and ready to use. The native C++ library must be compiled before debugging for FFI functionality to work properly. 