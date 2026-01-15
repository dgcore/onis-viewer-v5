#include "../../../include/database/items/db_user.hpp"
#include "../../../include/database/site_database.hpp"
#include "../../../include/services/requests/request_exceptions.hpp"
#include "../../../include/services/requests/request_service.hpp"

#include <jwt-cpp/jwt.h>

////////////////////////////////////////////////////////////////////////////////
// request_service_authenticate class
////////////////////////////////////////////////////////////////////////////////

void request_service::process_authenticate_request(
    [[maybe_unused]] const request_data_ptr& req) {
  // Verify input parameters:
  onis::database::item::verify_string_value(req->input_json, "username", false,
                                            false);
  onis::database::item::verify_string_value(req->input_json, "password", false,
                                            false);

  // Get database connection:
  request_database db(this);

  // Read input:
  std::string username = req->input_json["username"].get<std::string>();
  std::string password = req->input_json["password"].get<std::string>();

  // Get the site:
  json site(json::object());
  db->find_single_site(0, onis::database::lock_mode::NO_LOCK, nullptr, site);

  // Try to get a user from the authentication info:
  json user(json::object());
  db->find_user_for_session(site[BASE_SEQ_KEY].get<std::string>(), username,
                            password, onis::database::info_all, user);

  // generate a token for the session:
  auto now = std::chrono::system_clock::now();
  auto token = jwt::create()
                   .set_issuer("onis_site_server")                      // iss
                   .set_subject(user[BASE_SEQ_KEY].get<std::string>())  // sub
                   .set_audience("onis_api")  // aud (optional but recommended)
                   .set_issued_at(now)        // iat
                   .set_expires_at(now + std::chrono::hours{1})  // exp
                   .set_payload_claim("role", jwt::claim(std::string("user")))
                   .sign(jwt::algorithm::hs256{std::string("secret")});

  // create the user session:
  request_session_ptr session = request_session::create(token);
  session->site_id = site[BASE_SEQ_KEY].get<std::string>();
  session->user_id = user[BASE_SEQ_KEY].get<std::string>();
  session->login = user[US_LOGIN_KEY].get<std::string>();
  session->superuser = user[US_SUPERUSER_KEY].get<int>() != 0;

  // Register the session:
  register_session(session);

  // Add the user to the output:
  req->write_output([&](json& output) {
    output["user"] = json::object();
    onis::database::user::create(
        output["user"],
        onis::database::info_user_login | onis::database::info_user_identity);
    output["user"][US_LOGIN_KEY] = user[US_LOGIN_KEY];
    output["user"][US_FAMILY_NAME_KEY] = user[US_FAMILY_NAME_KEY];
    output["user"][US_FIRST_NAME_KEY] = user[US_FIRST_NAME_KEY];
    output["user"][US_PREFIX_KEY] = user[US_PREFIX_KEY];
    output["user"][US_SUFFIX_KEY] = user[US_SUFFIX_KEY];
  });
}
