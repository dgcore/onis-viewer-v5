#include "../../../include/database/items/db_role.hpp"
#include "../../../include/database/items/db_source.hpp"
#include "../../../include/database/items/db_user.hpp"
#include "../../../include/database/site_database.hpp"
#include "../../../include/services/requests/request_exceptions.hpp"
#include "../../../include/services/requests/request_service.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

#include <jwt-cpp/jwt.h>

////////////////////////////////////////////////////////////////////////////////
// request_service_authenticate
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
  std::string username = req->input_json["username"].asString();
  std::string password = req->input_json["password"].asString();

  // Get the site:
  json site(Json::objectValue);
  db->find_single_site(0, onis::database::lock_mode::NO_LOCK, nullptr, site);

  // Try to get a user from the authentication info:
  json user(Json::objectValue);
  db->find_user_for_session(site[BASE_SEQ_KEY].asString(), username, password,
                            onis::database::info_all, user);

  // generate a token for the session:
  auto now = std::chrono::system_clock::now();
  auto token = jwt::create()
                   .set_issuer("onis_site_server")              // iss
                   .set_subject(user[BASE_SEQ_KEY].asString())  // sub
                   .set_audience("onis_api")  // aud (optional but recommended)
                   .set_issued_at(now)        // iat
                   .set_expires_at(now + std::chrono::hours{1})  // exp
                   .set_payload_claim("role", jwt::claim(std::string("user")))
                   .sign(jwt::algorithm::hs256{std::string("secret")});

  // create the user session:
  request_session_ptr session = request_session::create(token);
  session->site_id = site[BASE_SEQ_KEY].asString();
  session->user_id = user[BASE_SEQ_KEY].asString();
  session->login = user[US_LOGIN_KEY].asString();
  session->superuser = user[US_SUPERUSER_KEY].asInt() != 0;

  // retrieve all the roles of the site, and store them in a map (this is used
  // to avoid multiple database accesses):
  /*std::unordered_map<std::string, const Json::Value&> roles;
  db->find_all_roles(site[BASE_SEQ_KEY].asString(), roles);
  for (const auto& role : roles) {
    session->roles[role[RO_SEQ_KEY].asString()] = role;
  }*/

  // analyze the partition access:
  // analyze_partition_access(session, user, roles, db);

  Json::Value config(Json::objectValue);
  get_user_configuration(db, session, config);

  // Register the session:
  register_session(session);

  // Add the user to the output:
  req->write_output([&](json& output) {
    output["user"] = Json::Value(Json::objectValue);
    onis::database::user::create(
        output["user"],
        onis::database::info_user_login | onis::database::info_user_identity);
    output["user"][US_LOGIN_KEY] = user[US_LOGIN_KEY];
    output["user"][US_FAMILY_NAME_KEY] = user[US_FAMILY_NAME_KEY];
    output["user"][US_FIRST_NAME_KEY] = user[US_FIRST_NAME_KEY];
    output["user"][US_PREFIX_KEY] = user[US_PREFIX_KEY];
    output["user"][US_SUFFIX_KEY] = user[US_SUFFIX_KEY];
    output["config"] = config;
  });
}

void request_service::get_user_configuration(const request_database& db,
                                             const request_session_ptr& session,
                                             Json::Value& config) const {
  // default parameters:
  config["version"] = "1.0.0";

  // create the source nodes:
  config["sources"] = Json::Value(Json::arrayValue);
  create_configuration_source_nodes(db, session, config["sources"]);
}

void request_service::create_configuration_source_nodes(
    const request_database& db, const request_session_ptr& session,
    Json::Value& sources) const {
  std::uint32_t source_flags = onis::database::info_all;
  Json::Value& site = sources.append(Json::Value(Json::objectValue));
  onis::database::source::create(site, source_flags);
  site[BASE_SEQ_KEY] = onis::util::uuid::generate_random_uuid();
  site[SO_NAME_KEY] = "Site";
  site[SO_SOURCE_ID_KEY] = "SITE";
  site[SO_TYPE_KEY] = onis::database::source::type_site;

  Json::Value& partitions =
      site[SO_CHILDREN_KEY].append(Json::Value(Json::objectValue));
  onis::database::source::create(partitions, source_flags);
  partitions[BASE_SEQ_KEY] = onis::util::uuid::generate_random_uuid();
  partitions[SO_NAME_KEY] = "Partitions";
  partitions[SO_SOURCE_ID_KEY] = "PARTITIONS";
  partitions[SO_TYPE_KEY] = onis::database::source::type_partitions;

  Json::Value& parent = partitions[SO_CHILDREN_KEY];
  Json::Value all_partitions_from_database(Json::arrayValue);
  db->find_partitions_for_site(
      session->site_id, onis::database::info_partition_name, 0, 0,
      onis::database::lock_mode::NO_LOCK, all_partitions_from_database);
  for (const auto& partition : all_partitions_from_database) {
    Json::Value& node = parent.append(Json::Value(Json::objectValue));
    onis::database::source::create(node, source_flags);
    node[BASE_SEQ_KEY] = onis::util::uuid::generate_random_uuid();
    node[SO_NAME_KEY] = partition[PT_NAME_KEY].asString();
    node[SO_SOURCE_ID_KEY] = partition[BASE_SEQ_KEY].asString();
    node[SO_TYPE_KEY] = onis::database::source::type_partition;
  }
}

void request_service::analyze_partition_access(
    const request_session_ptr& session, const Json::Value& user,
    const std::unordered_map<std::string, const Json::Value&>& roles,
    const request_database& db) const {
  if (session->superuser) {
    // superuser: all partitions, albums, and smart albums
    session->partition_mode =
        onis::database::partition_access_mode::ALL_PARTITIONS |
        onis::database::partition_access_mode::ALL_ALBUMS |
        onis::database::partition_access_mode::ALL_SMART_ALBUMS;
    session->partition_access.clear();
  } else {
    // non-superuser: analyze the partition access:
    const Json::Value& partition_access = user[US_PARTITION_ACCESS_KEY];
    const auto partition_mode = partition_access[PTA_MODE_KEY].asInt();
    if (partition_mode == 0)
      session->partition_mode = onis::database::partition_access_mode::NONE;
    else {
      session->partition_mode =
          static_cast<onis::database::partition_access_mode>(partition_mode);
      if (session->partition_mode ==
          onis::database::partition_access_mode::LIMITED_ACCESS) {
        for (const auto& access_item : partition_access[PTA_PARTITIONS_KEY]) {
          std::string partition_id = access_item[PTAI_ID_KEY].asString();
          onis::database::partition_access_mode mode =
              static_cast<onis::database::partition_access_mode>(
                  access_item[PTAI_MODE_KEY].asInt());
          std::uint32_t permission = access_item[PTAI_PERMISSION_KEY].asInt();
          session->partition_access[partition_id] =
              std::make_pair(mode, permission);
        }
      }
      // analyze the partition access from the user's membership:
      if (partition_access[PTA_INHERIT_KEY].asInt() != 0) {
        std::set<std::string>
            circular_loop;  // use to detect if we have a circular membership
                            // loop that would lead to a crash of the server
        const Json::Value& membership = user[US_MEMBERSHIP_KEY];
        for (const auto& membership_item : membership) {
          std::string role_id = membership_item.asString();
          analyze_partition_access_from_role(session, role_id, roles,
                                             circular_loop, db);
        }
      }
    }
  }
}

void request_service::analyze_partition_access_from_role(
    const request_session_ptr& session, const std::string& role_id,
    const std::unordered_map<std::string, const Json::Value&>& roles,
    std::set<std::string>& circular_loop, const request_database& db) const {
  if (session->superuser)
    return;
  if (circular_loop.find(role_id) != circular_loop.end()) {
    throw request_exception(EOS_CIRCULAR, "Circular membership detected");
  }
  // mark the role as done
  circular_loop.insert(role_id);

  try {
    const Json::Value& role = roles.at(role_id);
    if (role[RO_ACTIVE_KEY].asInt() != 1)
      return;
    // analyze the partition access:
    const Json::Value& partition_access = role[RO_PARTITION_ACCESS_KEY];
    if (partition_access[PTA_ACTIVE_KEY].asInt() == 0)
      return;

    /*s32 mode = superuser ?
    onis::server::partition_access::all_partitions|onis::server::partition_access::all_albums|onis::server::partition_access::all_smart_albums
    : access[PTA_MODE_KEY].asInt(); if (mode &
    onis::server::partition_access::all_partitions|| mode &
    onis::server::partition_access::all_albums|| mode &
    onis::server::partition_access::all_smart_albums) {*/

    if (role[RO_INHERIT_KEY].asInt() == 1) {
      for (const auto& parent_id : role[RO_MEMBERSHIP_KEY]) {
        analyze_partition_access_from_role(session, parent_id.asString(), roles,
                                           circular_loop, db);
      }
    }
  } catch (const std::out_of_range& e) {
    throw request_exception(EOS_NOT_FOUND, "Role not found: " + role_id);
  }
}
