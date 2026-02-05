#include "../../../include/network/drogon/drogon_http_server.hpp"
#include <json/json.h>
#include <algorithm>
#include <cstdlib>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <regex>
#include <sstream>

////////////////////////////////////////////////////////////////////////////////
// drogon_http_server
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// static constructor
//------------------------------------------------------------------------------

drogon_http_server_ptr drogon_http_server::create(
    const request_service_ptr& srv, const config_service_ptr& config) {
  return std::make_shared<drogon_http_server>(srv, config);
}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

drogon_http_server::drogon_http_server(const request_service_ptr& srv,
                                       const config_service_ptr& config)
    : rqsrv_(srv), config_service_(config) {
  std::cout << "drogon_http_server: Constructor" << std::endl;
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

drogon_http_server::~drogon_http_server() {
  std::cout << "drogon_http_server: Destructor" << std::endl;
}

//------------------------------------------------------------------------------
// init / exit
//------------------------------------------------------------------------------

void drogon_http_server::init_instance() {
  onis::thread::init_instance();
  std::cout << "drogon_http_server: init_instance" << std::endl;

  controller_ = http_drogon_controller::create(rqsrv_);
  th_ = std::thread(worker_thread, this, controller_);
}

void drogon_http_server::exit_instance() {
  std::cout << "drogon_http_server: exit_instance" << std::endl;
  drogon::app().quit();
  if (th_.joinable()) {
    th_.join();
  }
  onis::thread::exit_instance();
}

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

request_service_ptr drogon_http_server::get_request_service() const {
  return rqsrv_;
}

config_service_ptr drogon_http_server::get_config_service() const {
  return config_service_;
}

//------------------------------------------------------------------------------
// worker thread
//------------------------------------------------------------------------------

void drogon_http_server::worker_thread(drogon_http_server* server,
                                       http_drogon_controller_ptr controller) {
  try {
    // Get configuration values
    auto config = server->get_config_service();
    if (!config) {
      std::cerr << "drogon_http_server: No config service available"
                << std::endl;
      return;
    }

    int http_port = config->get_http_port();
    int https_port = config->get_https_port();
    bool ssl_enabled = config->is_ssl_enabled();
    std::string cert_file = config->get_ssl_certificate_file();
    std::string key_file = config->get_ssl_private_key_file();

    std::cout << "drogon_http_server: Configuring server with:" << std::endl;
    std::cout << "  HTTP port: " << http_port << std::endl;
    std::cout << "  HTTPS port: " << https_port << std::endl;
    std::cout << "  SSL enabled: " << (ssl_enabled ? "yes" : "no") << std::endl;
    if (ssl_enabled) {
      std::cout << "  Certificate file: " << cert_file << std::endl;
      std::cout << "  Private key file: " << key_file << std::endl;
    }

    // Configure Drogon with config values
    drogon::app()
        .addListener("0.0.0.0", https_port, true)   // HTTPS listener
        .addListener("0.0.0.0", http_port, false);  // HTTP listener

    // Set SSL files only if SSL is enabled
    if (ssl_enabled) {
      drogon::app().setSSLFiles(cert_file, key_file);
    }

    // Configure Drogon for large file uploads with streaming support
    // setUploadPath: Directory where Drogon saves uploaded files temporarily
    // setClientMaxBodySize: Maximum total body size (11GB for large DICOM
    // files) setClientMaxMemoryBodySize: Maximum body size to keep in memory
    // (4MB)
    //   Files larger than this are automatically streamed to disk
    std::filesystem::path uploadPath =
        std::filesystem::temp_directory_path() / "onis_uploads";
    std::filesystem::create_directories(uploadPath);

    drogon::app().setThreadNum(10);

    drogon::app()
        .setUploadPath(uploadPath.string())
        .setClientMaxBodySize(11ULL * 1024 * 1024 * 1024)  // 11GB max
        .setClientMaxMemoryBodySize(4 * 1024 *
                                    1024);  // 4MB in memory, rest streamed

    // Register custom handler for /dicom/import using MultiPartParser
    // MultiPartParser handles streaming automatically - files larger than
    // setClientMaxMemoryBodySize are streamed to disk, not loaded in memory
    /*drogon::app().registerHandler(
        "/dicom/import",
        [](const drogon::HttpRequestPtr& req,
           std::function<void(const drogon::HttpResponsePtr&)>&& callback) {
          try {
            // Check if this is a multipart/form-data request with file upload
            std::string contentType = req->getHeader("Content-Type");
            bool isMultipart =
                contentType.find("multipart/form-data") != std::string::npos;

            std::cerr << "drogon_http_server: /dicom/import - Content-Type: "
                      << contentType << std::endl;
            std::cerr << "drogon_http_server: /dicom/import - isMultipart: "
                      << (isMultipart ? "true" : "false") << std::endl;

            if (!isMultipart) {
              Json::Value errorData;
              errorData["success"] = false;
              errorData["error"] =
                  "Request must be multipart/form-data for file upload";
              auto resp = drogon::HttpResponse::newHttpJsonResponse(errorData);
              resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
              return callback(resp);
            }

            // Use Drogon's MultiPartParser which handles streaming
            // automatically
            // Files larger than setClientMaxMemoryBodySize are streamed to
            // disk, not loaded in memory
            drogon::MultiPartParser parser;

            // Log request details for debugging
            std::cerr << "drogon_http_server: /dicom/import - Request method: "
                      << req->getMethodString() << std::endl;
            std::cerr
                << "drogon_http_server: /dicom/import - Request body size: "
                << req->body().length() << std::endl;

            int parseResult = parser.parse(req);
            std::cerr
                << "drogon_http_server: /dicom/import - parse() returned: "
                << parseResult << std::endl;

            if (parseResult != 0) {
              Json::Value errorData;
              errorData["success"] = false;
              errorData["error"] =
                  "Failed to parse multipart/form-data (error code: " +
                  std::to_string(parseResult) + ")";
              std::cerr
                  << "drogon_http_server: /dicom/import - Parse failed with "
                     "error code: "
                  << parseResult << std::endl;
              auto resp = drogon::HttpResponse::newHttpJsonResponse(errorData);
              resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
              return callback(resp);
            }

            // Get uploaded files (streamed to disk if >
            // setClientMaxMemoryBodySize)
            const auto& files = parser.getFiles();
            std::cerr
                << "drogon_http_server: /dicom/import - parser.getFiles() "
                   "size: "
                << files.size() << std::endl;

            if (files.empty()) {
              Json::Value errorData;
              errorData["success"] = false;
              errorData["error"] = "No file found in upload";
              auto resp = drogon::HttpResponse::newHttpJsonResponse(errorData);
              resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
              return callback(resp);
            }

            // Get form fields
            const auto& parameters = parser.getParameters();
            Json::Value formFields(Json::objectValue);
            for (const auto& param : parameters) {
              formFields[param.first] = param.second;
            }

            // Find the file part (usually the first file or one with specific
            // field name)
            const drogon::HttpFile* uploadFile = nullptr;
            std::string fieldName;
            for (const auto& file : files) {
              // Look for file with field name "file" or use first file
              std::string itemName = file.getItemName();
              if (itemName == "file" || uploadFile == nullptr) {
                uploadFile = &file;
                fieldName = itemName;
                if (itemName == "file")
                  break;  // Prefer "file" field
              }
            }

            if (!uploadFile) {
              Json::Value errorData;
              errorData["success"] = false;
              errorData["error"] = "No file found in upload";
              auto resp = drogon::HttpResponse::newHttpJsonResponse(errorData);
              resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
              return callback(resp);
            }

            // Create final destination path
            std::filesystem::path tmpDir =
                std::filesystem::temp_directory_path();
            std::string tmpFileName = "onis_dicom_upload_" +
                                      std::to_string(std::time(nullptr)) + "_" +
                                      std::to_string(std::rand()) + ".dcm";
            std::filesystem::path tmpFilePath = tmpDir / tmpFileName;

            // Save the file to final location
            // saveAs() handles the copy efficiently, even for large files
            uploadFile->saveAs(tmpFilePath.string());

            // Get file info
            size_t fileSize = 0;
            if (std::filesystem::exists(tmpFilePath)) {
              fileSize = std::filesystem::file_size(tmpFilePath);
            }

            // Create success response
            Json::Value responseData;
            responseData["success"] = true;
            responseData["message"] =
                "File uploaded successfully via streaming";
            responseData["tmpFilePath"] = tmpFilePath.string();
            responseData["fileSize"] = static_cast<Json::Int64>(fileSize);
            responseData["originalFileName"] = uploadFile->getFileName();
            responseData["fieldName"] = fieldName;
            if (!formFields.empty()) {
              responseData["formFields"] = formFields;
            }

            auto resp = drogon::HttpResponse::newHttpJsonResponse(responseData);
            resp->setStatusCode(drogon::HttpStatusCode::k200OK);
            callback(resp);
          } catch (const std::exception& e) {
            Json::Value errorData;
            errorData["success"] = false;
            errorData["error"] =
                std::string("Error processing file: ") + e.what();
            auto resp = drogon::HttpResponse::newHttpJsonResponse(errorData);
            resp->setStatusCode(
                drogon::HttpStatusCode::k500InternalServerError);
            callback(resp);
          }
        },
        {drogon::Post});*/

    drogon::app().registerController(controller);

    // Run Drogon directly in this thread (not detached)
    std::cout << "drogon_http_server: Starting drogon server" << std::endl;
    drogon::app().run();
    std::cout << "drogon_http_server: Drogon server stopped" << std::endl;
  } catch (const std::exception& ex) {
    std::cerr << "drogon_http_server: Exception in worker thread: " << ex.what()
              << std::endl;
  }
}
