#include "../../../include/network/drogon/drogon_http_controller.hpp"
#include <json/json.h>
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
    resp = drogon::HttpResponse::newHttpResponse();
    resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
  } else {
    resp = drogon::HttpResponse::newHttpResponse();
    resp->setStatusCode(drogon::HttpStatusCode::k400BadRequest);
  }
  return callback(resp);
}
