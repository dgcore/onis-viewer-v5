cmake_minimum_required(VERSION 3.14)
project(onis_viewer_macos LANGUAGES CXX)

# Créer la bibliothèque C++ native
add_library(onis_core SHARED
  "../../native/onis_core.cpp"
  "../../native/onis_core.h"
)

# Paramètres de compilation pour macOS
target_compile_features(onis_core PUBLIC cxx_std_17)
target_compile_options(onis_core PRIVATE -Wall -Wextra)

# Définir le nom de sortie de la bibliothèque
set_target_properties(onis_core PROPERTIES
  LIBRARY_OUTPUT_NAME "onis_core"
  PREFIX "lib"
  SUFFIX ".dylib"
) 