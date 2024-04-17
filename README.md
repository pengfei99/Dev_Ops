# Dev_Ops

In this repo, I will store various tools to manage Linux servers(e.g. ansible playbook, etc. ).


# Install and configure ansible

## 1  Installing Ansible

To begin using Ansible as a means of managing your server infrastructure, you need to install the Ansible software 
on the machine that will serve as the `Ansible control node`.

From your control node, run the following command to include the official project’s PPA (personal package archive) in
your system’s list of sources:

```shell
sudo apt-add-repository ppa:ansible/ansible
# Press ENTER when prompted to accept the PPA addition.

# Next, refresh your system’s package index so that it is aware of the packages available in the newly included PPA:
sudo apt update

# Following this update, you can install the Ansible software with:
sudo apt install ansible

# check the installed ansible version
```


Your Ansible control node now has all the software required to administer your hosts. Next, we will go over how 
to add your hosts to the control node’s inventory file so that it can control them.

## 2  Setting Up the Inventory File

The **inventory file** contains information about the hosts you’ll manage with Ansible. You can include 
anywhere from one to several hundred servers in your inventory file, and hosts can be organized into groups and 
subgroups. The inventory file is also often used to set variables that will be valid only for specific hosts or 
groups, in order to be used within playbooks and templates. Some variables can also affect the way a playbook is run, 
like the `ansible_python_interpreter` variable that we’ll see in a moment.

To edit the contents of your default Ansible inventory, open the **/etc/ansible/hosts** file using your text 
editor of choice, on your Ansible control node:
```shell
sudo nano /etc/ansible/hosts
```

> Note: Although Ansible typically creates a default inventory file at /etc/ansible/hosts, you are free to create 
inventory files in any location that better suits your needs. In this case, you’ll need to provide the path to 
your custom inventory file with the -i parameter when running Ansible commands and playbooks. Using per-project 
> inventory files is a good practice to minimize the risk of running a playbook on the wrong group of servers.

Below is an example of `/etc/ansible/hosts`. It defines a group named `[servers]` with three different servers 
in it. Each server is identified by a custom alias: server1, server2, and server3, and associated with their IP address


```text
[servers]
server1 ansible_host=203.0.113.111
server2 ansible_host=203.0.113.112
server3 ansible_host=203.0.113.113

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

> The all:vars subgroup sets the ansible_python_interpreter host parameter that will be valid for all hosts included 
  in this inventory. This parameter makes sure the remote server uses the /usr/bin/python3 Python 3 executable 
  instead of /usr/bin/python (Python 2.7), which is not present on recent Debian versions.

> The group name can't contain special character such as - * &

When you finish editing the `/etc/ansible/hosts`, you can check the server lists in the inventory with the below command

```shell
ansible-inventory --list -y
```


## 3  Testing Connection

Now we can test our ansible setup. The below command will use a built-in module `ping` to run a connectivity test on 
all nodes from your `default inventory (/etc/ansible/hosts)`, it will test:

- if hosts are accessible;
- if you have valid SSH credentials;
- if hosts are able to run Ansible modules using Python.


The `-u` argument to specify the remote system user. When not provided, Ansible will try to connect as your current 
system user on the remote node.

The `--connection-password-file` argument can read a file which contains your ssh password

```shell
# create a file to store your password, you can name it as you want. The file name has no impact at all
echo "your_password_here" > sudo_pass.txt
# change the acl, so only you can access it
chmod 600 sudo_password.txt

ansible all -m ping -u pliu --connection-password-file=/etc/ansible/sudo_pass.txt
```


## 4  Running Ad-Hoc Commands (Optional)

After confirming that your `Ansible control node` is able to communicate with your hosts, you can start running ad-hoc commands and playbooks on your servers.

The `-a` argument allow you to run a shell command on the  `Ansible control node`.

```shell
# The general form is
ansible [host-pattern] -m [module] -a “[module options]”

# check disk usage
ansible all -a "df -h" -u pliu --connection-password-file=/etc/ansible/sudo_pass.txt

# check server uptime
ansible all -a "uptime" -u pliu --connection-password-file=/etc/ansible/sudo_pass.txt

# use the apt module to install a package
ansible all -m apt -a "name=htop state=latest" -u pliu --connection-password-file=/etc/ansible/sudo_pass.txt
```

> You can replace all by a group name. In that case, the target host will be only the servers in the given group

**Most modules of Ansible are idempotent, which implies that the changes are applied only if needed.**   