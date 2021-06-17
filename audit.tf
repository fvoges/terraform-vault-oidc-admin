resource "vault_audit" "file" {
  type = "file"

  options = {
    // file_path = "/tmp/vault_audit.log"
    file_path = "/var/log/vault/audit.log"
  }
}

resource "vault_audit" "syslog" {
  type = "syslog"
  options = {}
}

