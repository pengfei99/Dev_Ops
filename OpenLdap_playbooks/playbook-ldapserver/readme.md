## Deploy an OpenLDAP server (slapd) on an Ubuntu host

This Ansible playbook deploys a full OpenLDAP server (slapd daemon) on an Ubuntu host.

- Expects Ubuntu 14.04 hosts

The server can support StartTLS if `slapd_tls_enabled` is `True` and can also regenerate admin passwords (SSHA) if needed thank to the `slapd_admin_fgenpw` option.

Extensive monitoring is enabled and log files will be written in /var/log/ldap with log rotation enabled properly.

