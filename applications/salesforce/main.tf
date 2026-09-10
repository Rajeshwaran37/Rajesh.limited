data "azuread_client_config" "current" {}

########################
# APPLICATION
########################

resource "azuread_application" "app" {
  display_name = var.application_name

  owners = concat(
    [data.azuread_client_config.current.object_id],
    var.owner_object_ids
  )

  feature_tags {
    enterprise = true
    gallery    = false
  }
}

########################
# SERVICE PRINCIPAL
########################

resource "azuread_service_principal" "app" {
  client_id = azuread_application.app.client_id

  owners = concat(
    [data.azuread_client_config.current.object_id],
    var.owner_object_ids
  )
}

########################
# APP ROLE - USER
########################

resource "azuread_application_app_role" "user" {
  application_id = azuread_application.app.id

  role_id              = "11111111-1111-1111-1111-111111111111"
  allowed_member_types = ["User"]

  display_name = "User"
  description  = "Standard User Access"
  value        = "User"
}

########################
# APP ROLE - ADMIN
########################

resource "azuread_application_app_role" "admin" {
  application_id = azuread_application.app.id

  role_id              = "22222222-2222-2222-2222-222222222222"
  allowed_member_types = ["User"]

  display_name = "Admin"
  description  = "Administrative Access"
  value        = "Admin"
}

########################
# GROUPS
########################

resource "azuread_group" "users" {
  display_name     = "${var.application_name}_Users"
  security_enabled = true
}

resource "azuread_group" "admins" {
  display_name     = "${var.application_name}_Admins"
  security_enabled = true
}

########################
# ROLE ASSIGNMENTS
########################

resource "azuread_app_role_assignment" "user_assignment" {
  app_role_id         = azuread_application_app_role.user.role_id
  principal_object_id = azuread_group.users.object_id
  resource_object_id  = azuread_service_principal.app.object_id
}

resource "azuread_app_role_assignment" "admin_assignment" {
  app_role_id         = azuread_application_app_role.admin.role_id
  principal_object_id = azuread_group.admins.object_id
  resource_object_id  = azuread_service_principal.app.object_id
}

########################
# CLAIMS POLICY
########################

resource "azuread_claims_mapping_policy" "app" {

  display_name = "${var.application_name}-claims-policy"

  definition = [
    jsonencode({
      ClaimsMappingPolicy = {
        Version = 1
        IncludeBasicClaimSet = "true"
      }
    })
  ]
}

resource "azuread_service_principal_claims_mapping_policy_assignment" "app" {
  service_principal_id     = azuread_service_principal.app.id
  claims_mapping_policy_id = azuread_claims_mapping_policy.app.id
}