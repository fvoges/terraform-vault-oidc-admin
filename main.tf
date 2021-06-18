
resource "vault_jwt_auth_backend" "default" {
  description        = var.oidc_description
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = var.oidc_discovery_url
  oidc_client_id     = var.oidc_client_id
  oidc_client_secret = var.oidc_client_secret
  default_role       = "default"
  tune {
    listing_visibility = "unauth"
    max_lease_ttl      = "8760h"
    default_lease_ttl  = "8760h"
    token_type         = "default-service"
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
  allowed_redirect_uris = ["http://localhost:8250/oidc/callback","http://${var.vault_hostname}:8200/ui/vault/auth/oidc/oidc/callback"]
  oidc_scopes           = ["https://graph.microsoft.com/.default"]
}

resource "vault_identity_group" "vault_admins" {
  name     = var.admins_group_name
  type     = "external"
  metadata = var.admins_group_metadata
  policies = [vault_policy.vault_admin.name]
}

resource "vault_identity_group_alias" "default" {
  name           = var.oidc_group_alias_name
  mount_accessor = vault_jwt_auth_backend.default.accessor
  canonical_id   = vault_identity_group.vault_admins.id
}

data "vault_policy_document" "admin_policy" {
  rule {
    description  = "Read system health check"
    path         = "sys/health"
    capabilities = ["read", "sudo"]
  }

  rule {
    description  = "Create and manage namespaces"
    path         = "sys/namespaces/*"
    capabilities = ["create", "read", "update", "delete", "list"]
  }

  rule {
    description  = "Create and manage identities"
    path         = "identity/*"
    capabilities = ["create", "read", "update", "delete", "list"]
  }

  # Create and manage ACL policies broadly across Vault
  rule {
    description  = "List existing policies"
    path         = "sys/policies/acl"
    capabilities = ["list"]
  }

  rule {
    description  = "Create and manage ACL policies"
    path         = "sys/policies/acl/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  # Enable and manage authentication methods broadly across Vault
  rule {
    description  = "Manage auth methods broadly across Vault"
    path         = "auth/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  rule {
    description  = "Create, update, and delete auth methods"
    path         = "sys/auth/*"
    capabilities = ["create", "update", "delete", "sudo"]
  }

  rule {
    description  = "List auth methods"
    path         = "sys/auth"
    capabilities = ["read"]
  }

  rule {
    description  = "Manage secrets engines"
    path         = "sys/mounts/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  rule {
    description  = "List existing secrets engines."
    path         = "sys/mounts"
    capabilities = ["read"]
  }
}

resource "vault_policy" "vault_admin" {
  name   = "vault-admin"
  policy = data.vault_policy_document.admin_policy.hcl
}
