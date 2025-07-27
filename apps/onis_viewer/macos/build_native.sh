#!/bin/bash

# Script pour compiler le code C++ natif sur macOS

set -e

# Dossier de sortie
BUILD_DIR="build_native"
mkdir -p $BUILD_DIR

# Compiler avec CMake
cmake -B $BUILD_DIR -S Runner
cmake --build $BUILD_DIR --config Release

# Copier la bibliothèque dans le bon dossier
cp $BUILD_DIR/libonis_core.dylib ../build/macos/Build/Products/Release/onis_viewer.app/Contents/MacOS/

echo "Compilation C++ native terminée pour macOS" 