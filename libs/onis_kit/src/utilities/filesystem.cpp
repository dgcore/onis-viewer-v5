#include "../../include/utilities/filesystem.hpp"
#include <algorithm>
#include <filesystem>
#include <fstream>
#include <vector>

namespace onis::util::filesystem {

bool find_folders(std::string& dir_path, std::vector<std::string>& result) {
  result.clear();
  try {
    if (!std::filesystem::exists(dir_path) ||
        !std::filesystem::is_directory(dir_path)) {
      return false;
    }

    for (const auto& entry : std::filesystem::directory_iterator(dir_path)) {
      if (entry.is_directory()) {
        result.push_back(entry.path().filename().string());
      }
    }

    std::sort(result.begin(), result.end());
    return true;
  } catch (...) {
    return false;
  }
}

void concat(std::string& dir, const std::string& name) {
  if (dir.empty()) {
    dir = name;
    return;
  }

  // Ensure dir ends with a separator
  if (dir.back() != '/' && dir.back() != '\\') {
    dir += '/';
  }

  dir += name;
}

void replace_anti_slash_by_slash(std::string& path) {
  std::replace(path.begin(), path.end(), '\\', '/');
}

std::string get_directory(const std::string& file_path, std::string* name) {
  try {
    std::filesystem::path path(file_path);
    std::filesystem::path dir = path.parent_path();
    std::string dir_str = dir.string();

    if (name != nullptr) {
      *name = path.filename().string();
    }

    // Replace backslashes with forward slashes for consistency
    replace_anti_slash_by_slash(dir_str);

    return dir_str;
  } catch (...) {
    if (name != nullptr) {
      *name = "";
    }
    return "";
  }
}

std::string get_relative_path(const std::string& full_path,
                              const std::string& dir) {
  try {
    std::filesystem::path full(full_path);
    std::filesystem::path base(dir);

    // Make paths absolute and canonical
    if (!full.is_absolute()) {
      full = std::filesystem::absolute(full);
    }
    if (!base.is_absolute()) {
      base = std::filesystem::absolute(base);
    }

    std::filesystem::path relative = std::filesystem::relative(full, base);
    std::string result = relative.string();
    replace_anti_slash_by_slash(result);
    return result;
  } catch (...) {
    return "";
  }
}

std::string create_directory(const std::string& dir, const std::string& base,
                             bool index) {
  try {
    std::filesystem::path base_path(base);
    std::filesystem::path dir_path(dir);

    // If dir is not absolute, make it relative to base
    if (!dir_path.is_absolute()) {
      dir_path = base_path / dir_path;
    }

    std::string result = dir_path.string();
    replace_anti_slash_by_slash(result);

    // Create directory if it doesn't exist
    if (!std::filesystem::exists(dir_path)) {
      std::filesystem::create_directories(dir_path);
    }

    // If index is true, append an index number if directory already exists
    if (index && std::filesystem::exists(dir_path)) {
      std::int32_t counter = 1;
      std::filesystem::path indexed_path = dir_path;
      std::string base_name = dir_path.filename().string();

      while (std::filesystem::exists(indexed_path)) {
        std::string indexed_name = base_name + "_" + std::to_string(counter);
        indexed_path = dir_path.parent_path() / indexed_name;
        counter++;
      }

      std::filesystem::create_directories(indexed_path);
      result = indexed_path.string();
      replace_anti_slash_by_slash(result);
    }

    return result;
  } catch (...) {
    return "";
  }
}

bool create_multi_directories(const std::string& dir) {
  try {
    std::filesystem::path dir_path(dir);
    return std::filesystem::create_directories(dir_path);
  } catch (...) {
    return false;
  }
}

bool delete_directory(const std::string& dir) {
  try {
    std::filesystem::path dir_path(dir);
    if (std::filesystem::exists(dir_path) &&
        std::filesystem::is_directory(dir_path)) {
      std::filesystem::remove_all(dir_path);
      return true;
    }
    return false;
  } catch (...) {
    return false;
  }
}

bool exist_directory(const std::string& dir) {
  try {
    std::filesystem::path dir_path(dir);
    return std::filesystem::exists(dir_path) &&
           std::filesystem::is_directory(dir_path);
  } catch (...) {
    return false;
  }
}

bool delete_file(const std::string& file_path) {
  try {
    std::filesystem::path path(file_path);
    if (std::filesystem::exists(path) &&
        std::filesystem::is_regular_file(path)) {
      return std::filesystem::remove(path);
    }
    return false;
  } catch (...) {
    return false;
  }
}

bool exist_file(const std::string& file_path) {
  try {
    std::filesystem::path path(file_path);
    return std::filesystem::exists(path) &&
           std::filesystem::is_regular_file(path);
  } catch (...) {
    return false;
  }
}

bool move_file(const std::string& file_path, const std::string& new_file_path) {
  try {
    std::filesystem::path source(file_path);
    std::filesystem::path dest(new_file_path);

    if (!std::filesystem::exists(source) ||
        !std::filesystem::is_regular_file(source)) {
      return false;
    }

    // Create destination directory if it doesn't exist
    std::filesystem::path dest_dir = dest.parent_path();
    if (!dest_dir.empty() && !std::filesystem::exists(dest_dir)) {
      std::filesystem::create_directories(dest_dir);
    }

    std::filesystem::rename(source, dest);
    return true;
  } catch (...) {
    return false;
  }
}

bool copy_file(const std::string& file_path, const std::string& new_file_path) {
  try {
    std::filesystem::path source(file_path);
    std::filesystem::path dest(new_file_path);

    if (!std::filesystem::exists(source) ||
        !std::filesystem::is_regular_file(source)) {
      return false;
    }

    // Create destination directory if it doesn't exist
    std::filesystem::path dest_dir = dest.parent_path();
    if (!dest_dir.empty() && !std::filesystem::exists(dest_dir)) {
      std::filesystem::create_directories(dest_dir);
    }

    std::filesystem::copy_file(
        source, dest, std::filesystem::copy_options::overwrite_existing);
    return true;
  } catch (...) {
    return false;
  }
}

bool has_tmp_extension(const std::string& file_path) {
  try {
    std::filesystem::path path(file_path);
    std::string ext = path.extension().string();

    // Convert to lowercase for comparison
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);

    // Common temporary file extensions
    return ext == ".tmp" || ext == ".temp" || ext == ".bak" || ext == ".swp" ||
           ext == ".~" || file_path.back() == '~';
  } catch (...) {
    return false;
  }
}

}  // namespace onis::util::filesystem