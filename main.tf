
resource "vault_auth_backend" "default" {
  type = "oidc"
  tune {
    max_lease_ttl     = "8760h"
    default_lease_ttl = "8760h"
  }
}

resource "vault_jwt_auth_backend" "default" {
  description        = var.oidc_description
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = var.oidc_discovery_url
  oidc_client_id     = var.oidc_client_id
  oidc_client_secret = var.oidc_client_secret
  tune {
    listing_visibility = "unauth"
  }
}

# we only have a default role that assigns a default policy
# we're going to use external groups to assign permissions
resource "vault_jwt_auth_backend_role" "default" {
  backend               = vault_jwt_auth_backend.default.path
  role_name             = "default"
  token_policies        = ["default"]
  user_claim            = "email"
  groups_claim          = "groups"
  role_type             = "oidc"
  allowed_redirect_uris = ["http://localhost:8200/ui/vault/auth/oidc/oidc/callback"]
  oidc_scopes           = ["https://graph.microsoft.com/.default"]
}

resource "vault_identity_group" "vault_admins" {
  name     = var.admins_group_name
  type     = "external"
  metadata = var.admins_group_metadata
}

resource "vault_identity_group_alias" "default" {
  name           = var.oidc_group_alias_name
  mount_accessor = vault_auth_backend.default.accessor
  canonical_id   = vault_identity_group.vault_admins.id
}

data "vault_policy_document" "default" {
  rule {
    path         = "secret/+/{{identity.groups.ids.${vault_identity_group.vault_admins.id}.metadata.env}}-{{identity.groups.ids.${vault_identity_group.vault_admins.id}.metadata.service}}/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "allow read of static secret object named after metadata keys"
  }
  rule {
    path         = "auth/token/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "create child tokens"
  }
}

resource "vault_policy" "default" {
  name   = "ad-group-default-kv-store"
  policy = data.vault_policy_document.default.hcl
}

resource "vault_identity_group_policies" "default" {
  group_id  = vault_identity_group.vault_admins.id
  exclusive = false
  policies  = [vault_policy.default.name]
}
