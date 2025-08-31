#include "../../../include/network/drogon/drogon_http_controller.hpp"

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
  this->rqsrv_ = srv;
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
  json responseData;
  responseData["success"] = true;
  responseData["message"] = "Authentication successful";
  responseData["user"]["username"] = "test";
  auto resp = drogon::HttpResponse::newHttpJsonResponse(responseData.dump());
  resp->setStatusCode(drogon::HttpStatusCode::k200OK);
  return callback(resp);
}

void http_drogon_controller::logout(
    const drogon::HttpRequestPtr& req,
    std::function<void(const drogon::HttpResponsePtr&)>&& callback) const {
  json responseData;
  responseData["success"] = true;
  responseData["message"] = "Logout successful";
  responseData["user"]["username"] = "test";
  auto resp = drogon::HttpResponse::newHttpJsonResponse(responseData.dump());
  resp->setStatusCode(drogon::HttpStatusCode::k200OK);
  return callback(resp);
}