# ONIS Viewer Native Backend

This folder contains the Dart side of the C++ backend bridge:

- `ffi_bindings.dart`: raw symbol bindings
- `backend_native.dart`: native loading + pointer lifetime
- `backend_service.dart`: high-level API for app layers

## Native side

Native C++ code is located in:

- `native/backend/include/onis_backend.h`
- `native/backend/src/onis_backend.cpp`
- `native/backend/CMakeLists.txt`

## Build (example)

```bash
cd native/backend
cmake -S . -B build
cmake --build build
```

Then place the generated dynamic library where the app can load it:

- macOS: `libonis_backend.dylib`
- Linux: `libonis_backend.so`
- Windows: `onis_backend.dll`
