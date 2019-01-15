# This playbook creates a snap shot of a vm, then does a yum update, at last, it will restart the vm

# Requirements

ansible v2.3 or above
python v2.6 or above
PyVmomi

# Tested on vSphere 5.5

# Official doc

ansible v2.3 http://ansible-manual.readthedocs.io/en/stable-2.3/vmware_guest_snapshot_module.html
ansible v2.4 http://docs.ansible.com/ansible/latest/vmware_guest_snapshot_module.html