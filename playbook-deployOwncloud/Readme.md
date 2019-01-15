# Install an owncloud server on a centos based Os.

1.In the install-ownCloud role, we install owncloud and required package
Then we install httpd demaon and configure the httpd for owncloud

2.In the config-ownCloud role, we config owncloud to connect to the externale database and fs(e.g. gpfs, nfs) 
 
Ps. The version of the owncloud which will be installed can be configured in the role install-ownCloud/defaults