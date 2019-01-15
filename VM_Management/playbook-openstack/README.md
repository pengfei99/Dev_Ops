Creat vm in openstack cloud
===============

This roles installs create a vm on the target openstack cloud. It uses a vm which has the right to connect to the openstack hypervisor. 

Requirements
------------

This role requires Ansible 1.9 or higher, and platform requirements are listed
in the metadata file.

Role Variables
--------------

The variables that can be passed to this role and a brief description about
them are as follows:

  1) nova creds for connecting hypervisor openstack. They are normally in ~/.novacreds/novarc.sh
  
auth_url: https://cckeystone.in2p3.fr:35357/v2.0/

user_name: pliu

password: changeMe

os_tenant_name: bioaster

  2) nova boot args for spawn vm

vm_name: cclintestldap

image_name: d34dfe78-70f6-49e0-b917-9bc5f4243117 (This can be obtain by nova image-list)

flavor_name: m1.small (This can be obtain by nova flavor-list)

cloud_keyName: bioaster_os (this key will be used to login into the created vm)

vm_hostName: cclintestldap.bioaster.org (vm url)

    

Dependencies
------------

None

License
-------

BSD

Author Information
------------------

Pengfei Liu


