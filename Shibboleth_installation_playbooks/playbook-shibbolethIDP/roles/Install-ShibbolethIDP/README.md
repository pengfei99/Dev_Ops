# Shibboleth

This role is used to install an **Identity Provider (IdP)**. To install
a **Service Provider (SP)** please use the [shibboleth-apache][sp] role.

[sp]: ../shibboleth-apache

## Usage

In order to use this role, several variables have to be defined.
This can be done in the playbook when assigning the role:

    - name: Set up and configure Shibboleth Identity Provider
      hosts: shibboleths
      roles:
        - { role: shibboleth,
            keystore_password: "{{ shibboleth_keystore_password }}",
            ssl_certificate: "{{ shibboleth_server_certificate }}",
            ssl_key: "{{ shibboleth_server_key }}",
            service_providers: [
              { entity_id: "https://www.bioaster.org/shibboleth",
                server_name: "www.bioaster.org",
                url: "http://www.bioaster.org",
                ssl_certificate: "{{ shibboleth_client_certificate }}",
                uid: "_e805c6e3a443cb2d83267991e220482009591b17"
              }
            ]
          }

## Test

Once deployed the service can be tested in 2 ways.

### Test the server

    lynx https://auth.bioaster.org:8443/idp/status

This should return a lot of information regarding the service.

### Test the exported attributes

From the installation folder of the IdP:

    $ su - jetty
    $ cd /opt/shibboleth-idp/
    $ ./bin/aacli.sh --requester=http://www.bioaster.org/secure \
                     --configDir=conf/ --principal="tlecarrour"

This should return an XML string with some attributes.

## TODO

- [ ] Clean `start.ini` to get rid of `login.*`

## Attributes

Attributes export depends on 2 steps:

- Attributes [definition](templates/attribute-resolver.xml.j2), that tells which attributes can be rertieved from
  which source and how;
- Attributes [filtering](templates/attribute-filter.xml.j2), that tells which attributes can be released to
  a specific service provider.

