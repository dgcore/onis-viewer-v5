#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace onis::util::filesystem {
bool find_folders(std::string& dir_path, std::vector<std::string>& result);
void concat(std::string& dir, const std::string& name);
void replace_anti_slash_by_slash(std::string& path);
std::string get_directory(const std::string& file_path,
                          std::string* name = NULL);
std::string get_relative_path(const std::string& full_path,
                              const std::string& dir);
std::string create_directory(const std::string& dir, const std::string& base,
                             bool index);
bool create_multi_directories(const std::string& dir);
bool delete_directory(const std::string& dir);
bool exist_directory(const std::string& dir);
bool delete_file(const std::string& file_path);
bool exist_file(const std::string& file_path);
bool move_file(const std::string& file_path, const std::string& new_file_path);
bool copy_file(const std::string& file_path, const std::string& new_file_path);
bool has_tmp_extension(const std::string& file_path);
}  // namespace onis::util::filesystem
