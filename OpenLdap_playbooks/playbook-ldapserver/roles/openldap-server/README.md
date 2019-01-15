openldap_server
===============

This roles installs the OpenLDAP server on the target machine. It has the
option to enable/disable SSL by setting it in defaults or overriding it.

Requirements
------------

This role requires Ansible 1.4 or higher, and platform requirements are listed
in the metadata file.

Role Variables
--------------

The variables that can be passed to this role and a brief description about
them are as follows:

    openldap_serverdomain_name: bioaster.org    # The domain prefix for ldap
    openldap_serverrootpw: passme              # This is the password for admin for openldap
    openldap_serverenable_ssl: true            # To enable/disable ssl for the ldap
    openldap_servercountry: FR                # The self signed ssl certificate parameters
    openldap_serverstate: Rhone-Alpes
    openldap_serverlocation: Lyon
    openldap_serverorganization: BIOASTER


Examples
--------

1) Configure an OpenLDAP server without SSL:

    - hosts: all
      roles:
      - role: bennojoy.openldap_server
        slapd_domain_name: bioaster.org
        slapd_adminpw: passme
        slapd_tls_enabled: false
       
2) Configure an OpenLDAP server with SSL:

    - hosts: all
      roles:
      - role: bennojoy.openldap_server
        slapd_domain_name: bioaster.org
        slapd_adminpw: passme
        slapd_tls_enabled: true
        slapd_tls_country: FR
        slapd_tls_state: Rhone-Alpes
        slapd_tls_location: Lyon
        slapd_tls_organization: BIOASTER

Dependencies
------------

None

License
-------

BSD

Author Information
------------------

Pengfei Liu


