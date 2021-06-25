# terraform-vault-oidc-admin

Example code to do initial Vault admin configuration using Terraform

- Spin up a Vault cluster
- Initialise Vault (`vault operator init`)
- Run `terraform apply` using this code to setup OIDC auth backend, configure admin policy, and assign it to an admin group from OIDC
- Login with Azure AD credentials to test OIDC, and verify that admins have the right permissions
- Revoke root token (`vault token revoke <root_token>`)
