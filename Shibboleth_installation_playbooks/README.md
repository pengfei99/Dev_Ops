What's Shibboleth?

======================================================================

Shibboleth is a software package for web single sign-on across or within organizational boundaries. It allows sites to make informed authorization decisions for individual access of protected online resources in a privacy-preserving manner.
-----------------------------------------------------------------------

Shibboleth is a server client architecture, Server side is called identity provider(IDP). Client side is called service provdier(SP).


========================================================================


The playbook-shibbolethSP install a shibboleth client on a centos 7 based server and configure apache to use it.

To complete the certifate and key variable, you may need to generated a selfsigned certificate and private key

$ openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

-nodes means ommit the passphrase for private key
