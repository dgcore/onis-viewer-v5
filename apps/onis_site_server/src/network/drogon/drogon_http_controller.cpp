#include "../../../include/network/drogon/drogon_http_controller.hpp"
#include <json/json.h>
#include <cstdlib>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <sstream>

////////////////////////////////////////////////////////////////////////////////
// drogon_http_controller
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

http_drogon_controller_ptr http_drogon_controller::create(
    const request_service_ptr& srv) {
  return std::make_shared<http_drogon_controller>(srv);
}

http_drogon_controller::http_drogon_controller(const request_service_ptr& srv) {
  rqsrv_ = srv;
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

http_drogon_controller::~http_drogon_controller() {}

//------------------------------------------------------------------------------
// Accounts
//------------------------------------------------------------------------------

void http_drogon_controller::authenticate(
    const drogon::HttpRequestPtr& req,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback) const {
  treat_post_request(req, callback, request_type::kAuthenticate);
}

void http_drogon_controller::logout(
    const drogon::HttpRequestPtr& req,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback) const {
  /*json responseData;
  responseData["success"] = true;
  responseData["message"] = "Logout successful";
  responseData["user"]["username"] = "test";
  auto resp = drogon::HttpResponse::newHttpJsonResponse(responseData.dump());
  resp->setStatusCode(drogon::HttpStatusCode::k200OK);
  return callback(resp);*/
}

//------------------------------------------------------------------------------
// Find Studies
//------------------------------------------------------------------------------

void http_drogon_controller::find_studies(
    const drogon::HttpRequestPtr& req,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback) const {
  treat_post_request(req, callback, request_type::kFindStudies);
}

//------------------------------------------------------------------------------
// Import
//------------------------------------------------------------------------------

void http_drogon_controller::dicom_import(
    const drogon::HttpRequestPtr& req,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback) const {
  try {
    request_data_ptr data = request_data::create(request_type::kImportDicom);

    // Check multipart/form-data
    std::string content_type = req->getHeader("Content-Type");
    bool is_multi_part =
        content_type.find("multipart/form-data") != std::string::npos;
    if (!is_multi_part) {
      auto resp = drogon::HttpResponse::newHttpResponse();
      resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
      return callback(resp);
    }

    drogon::MultiPartParser parser;
    int parse_result = parser.parse(req);
    if (parse_result != 0) {
      auto resp = drogon::HttpResponse::newHttpResponse();
      resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
      return callback(resp);
    }

    const auto& files = parser.getFiles();
    if (files.empty()) {
      auto resp = drogon::HttpResponse::newHttpResponse();
      resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
      return callback(resp);
    }

    // Form fields - convert parameters to Json::Value object
    const auto& parameters = parser.getParameters();
    Json::Reader reader;
    for (const auto& param : parameters) {
      data->input_json[param.first] = param.second;
    }

    // Pick file
    const drogon::HttpFile* upload_file = nullptr;
    std::string field_name;
    for (const auto& file : files) {
      std::string item_name = file.getItemName();
      if (item_name == "file" || upload_file == nullptr) {
        upload_file = &file;
        field_name = item_name;
        if (item_name == "file")
          break;
      }
    }

    if (!upload_file) {
      auto resp = drogon::HttpResponse::newHttpResponse();
      resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
      return callback(resp);
    }

    // Destination temp file
    std::filesystem::path tmp_dir = std::filesystem::temp_directory_path();
    std::string tmp_file_name = "onis_dicom_upload_" +
                                std::to_string(std::time(nullptr)) + "_" +
                                std::to_string(std::rand()) + ".dcm";
    std::filesystem::path tmp_file_path = tmp_dir / tmp_file_name;

    // Save uploaded content
    upload_file->saveAs(tmp_file_path.string());
    data->input_json["dicom_file_path"] = tmp_file_path.string();

    // Handle request:
    drogon::HttpResponsePtr resp;
    rqsrv_->process_request(data);
    data->read_output([&](const Json::Value& output) {
      resp = drogon::HttpResponse::newHttpJsonResponse(output);
    });
    resp->setStatusCode(drogon::HttpStatusCode::k200OK);
    callback(resp);
  } catch (const std::exception& e) {
    auto resp = drogon::HttpResponse::newHttpResponse();
    resp->setStatusCode(drogon::HttpStatusCode::k500InternalServerError);
    callback(resp);
  }
}

//------------------------------------------------------------------------------
// Treat Post Request
//------------------------------------------------------------------------------

void http_drogon_controller::treat_post_request(
    const drogon::HttpRequestPtr& req,
    std::function<void(const drogon::HttpResponsePtr&)>& callback,
    [[maybe_unused]] request_type type) const {
  drogon::HttpResponsePtr resp;
  auto& json_obj = req->getJsonObject();
  if (json_obj != nullptr) {
    request_data_ptr data = request_data::create(type);
    // Direct assignment - both use JsonCPP (Json::Value)
    data->input_json = *json_obj;
    rqsrv_->process_request(data);
    // INSERT_YOUR_CODE
    data->read_output([&](const Json::Value& output) {
      resp = drogon::HttpResponse::newHttpJsonResponse(output);
    });
    resp->setStatusCode(drogon::HttpStatusCode::k200OK);
  } else {
    resp = drogon::HttpResponse::newHttpResponse();
    resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
  }
  return callback(resp);
}
