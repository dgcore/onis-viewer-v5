#pragma once

#include <drogon/HttpController.h>
#include "../../../include/services/requests/request_service.hpp"

////////////////////////////////////////////////////////////////////////////////
// drogon_http_controller
////////////////////////////////////////////////////////////////////////////////

class http_drogon_controller;
typedef std::shared_ptr<http_drogon_controller> http_drogon_controller_ptr;

class http_drogon_controller
    : public drogon::HttpController<http_drogon_controller, false> {
public:
  // constructors:
  static http_drogon_controller_ptr create(const request_service_ptr& srv);
  http_drogon_controller(const request_service_ptr& srv);

  // cleanup:
  ~http_drogon_controller();

public:
  // routing table:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(http_drogon_controller::authenticate, "/accounts/authenticate",
                drogon::Post);
  ADD_METHOD_TO(http_drogon_controller::logout, "/accounts/logout",
                drogon::Post);
  ADD_METHOD_TO(http_drogon_controller::find_studies, "/studies/find",
                drogon::Post);
  ADD_METHOD_TO(http_drogon_controller::dicom_import, "/dicom/import",
                drogon::Post);
  METHOD_LIST_END

  // Accounts
  void authenticate(
      const drogon::HttpRequestPtr& req,
      std::function<void(const drogon::HttpResponsePtr&)>&& callback) const;
  void logout(
      const drogon::HttpRequestPtr& req,
      std::function<void(const drogon::HttpResponsePtr&)>&& callback) const;

  // Find Studies
  void find_studies(
      const drogon::HttpRequestPtr& req,
      std::function<void(const drogon::HttpResponsePtr&)>&& callback) const;

  // Import:
  void dicom_import(
      const drogon::HttpRequestPtr& req,
      std::function<void(const drogon::HttpResponsePtr&)>&& callback) const;

private:
  request_service_ptr rqsrv_;

  void treat_post_request(
      const drogon::HttpRequestPtr& req,
      std::function<void(const drogon::HttpResponsePtr&)>& callback,
      [[maybe_unused]] request_type type) const;
};