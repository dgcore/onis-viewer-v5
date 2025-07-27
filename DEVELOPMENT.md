# Development Guide - ONIS Viewer

This guide explains how to extend and develop ONIS Viewer with Flutter + FFI + C++.

## Project Architecture

### File Structure

```
onis_viewer/
├── lib/                    # Flutter/Dart code
│   ├── main.dart          # Application entry point
│   └── ffi/               # FFI bindings
│       └── onis_ffi.dart  # Dart <-> C++ interface
├── native/                # Native C++ code
│   ├── onis_core.h        # C++ function headers
│   └── onis_core.cpp      # C++ function implementation
├── windows/               # Windows configuration
├── macos/                 # macOS configuration
├── linux/                 # Linux configuration
├── android/               # Android configuration
└── ios/                   # iOS configuration
```

### Data Flow

```
Flutter UI (Dart) 
    ↓ (FFI)
Dart <-> C++ Bindings
    ↓ (Dynamic Library)
Native C++ Code
    ↓
Critical Functions (DICOM, OpenGL, etc.)
```

## Adding a New Feature

### 1. Declare the C++ Function

In `native/onis_core.h`:

```cpp
// New function to load a DICOM file
const char* onis_load_dicom_file(const char* file_path);

// New function to get image dimensions
void onis_get_image_dimensions(int* width, int* height);
```

### 2. Implement the C++ Function

In `native/onis_core.cpp`:

```cpp
const char* onis_load_dicom_file(const char* file_path) {
    // DICOM loading implementation
    // Return a status message
    return "DICOM file loaded successfully";
}

void onis_get_image_dimensions(int* width, int* height) {
    // Get dimensions from DICOM library
    *width = 512;
    *height = 512;
}
```

### 3. Add FFI Binding

In `lib/ffi/onis_ffi.dart`:

```dart
// C function type definitions
typedef OnisLoadDicomFileFunc = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef OnisGetImageDimensionsFunc = void Function(ffi.Pointer<ffi.Int32>, ffi.Pointer<ffi.Int32>);

// Dart function type definitions
typedef OnisLoadDicomFile = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef OnisGetImageDimensions = void Function(ffi.Pointer<ffi.Int32>, ffi.Pointer<ffi.Int32>);

class OnisCore {
  // ... existing code ...

  static late final OnisLoadDicomFile _onisLoadDicomFile;
  static late final OnisGetImageDimensions _onisGetImageDimensions;

  static void initialize() {
    // ... existing code ...
    
    _onisLoadDicomFile = _lib!
        .lookupFunction<OnisLoadDicomFileFunc, OnisLoadDicomFile>('onis_load_dicom_file');
    _onisGetImageDimensions = _lib!
        .lookupFunction<OnisGetImageDimensionsFunc, OnisGetImageDimensions>('onis_get_image_dimensions');
  }

  // Public methods
  static String loadDicomFile(String filePath) {
    if (!_initialized) initialize();
    final pathPtr = filePath.toNativeUtf8();
    final resultPtr = _onisLoadDicomFile(pathPtr);
    final result = _ptrToString(resultPtr);
    calloc.free(pathPtr);
    return result;
  }

  static Map<String, int> getImageDimensions() {
    if (!_initialized) initialize();
    final widthPtr = calloc<ffi.Int32>();
    final heightPtr = calloc<ffi.Int32>();
    _onisGetImageDimensions(widthPtr, heightPtr);
    final width = widthPtr.value;
    final height = heightPtr.value;
    calloc.free(widthPtr);
    calloc.free(heightPtr);
    return {'width': width, 'height': height};
  }
}
```

### 4. Use in Flutter Application

In `lib/main.dart` or a new widget:

```dart
class DicomViewer extends StatefulWidget {
  @override
  _DicomViewerState createState() => _DicomViewerState();
}

class _DicomViewerState extends State<DicomViewer> {
  String _status = '';
  Map<String, int>? _dimensions;

  void _loadDicomFile() {
    try {
      final status = OnisCore.loadDicomFile('/path/to/file.dcm');
      final dimensions = OnisCore.getImageDimensions();
      
      setState(() {
        _status = status;
        _dimensions = dimensions;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _loadDicomFile,
          child: Text('Load DICOM File'),
        ),
        Text('Status: $_status'),
        if (_dimensions != null)
          Text('Dimensions: ${_dimensions!['width']}x${_dimensions!['height']}'),
      ],
    );
  }
}
```

## Compilation and Testing

### Complete Build

```bash
./build_all.sh
```

### Platform-Specific Build

```bash
# macOS
cd macos && ./build_native.sh && cd .. && flutter build macos

# Linux
flutter build linux

# Windows
flutter build windows
```

### Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

## Best Practices

### 1. Memory Management

- Always free memory allocated with `calloc.free()`
- Use temporary pointers for character strings
- Check return errors from C++ functions

### 2. Error Handling

```dart
try {
  final result = OnisCore.someFunction();
  // Process the result
} catch (e) {
  // Handle the error
  print('FFI Error: $e');
}
```

### 3. Performance

- Avoid frequent FFI calls in loops
- Use buffers for large data
- Prefer batch calls over individual ones

### 4. Multi-Platform Compatibility

- Test on all target platforms
- Use compatible file paths
- Handle system library differences

## Next Steps

1. **DICOM Implementation**: Add a DICOM library (dcmtk, gdcm)
2. **OpenGL Visualization**: Integrate OpenGL for image display
3. **Streaming**: Implement image streaming
4. **Annotations**: Add annotation tools
5. **Hanging Protocols**: Display protocol system
6. **Testing**: Add unit and integration tests

## Useful Resources

- [Flutter FFI Documentation](https://docs.flutter.dev/development/platform-integration/c-interop)
- [Flutter FFI Examples](https://github.com/flutter/packages/tree/main/packages/ffi/example)
- [CMake Documentation](https://cmake.org/documentation/)
- [DICOM Libraries](https://dicom.offis.de/dcmtk.php) 