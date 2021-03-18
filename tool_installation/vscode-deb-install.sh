#! /bin/sh
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg

install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/

sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

apt install apt-transport-https -y

apt update

apt install code -y

rm -f packages.microsoft.gpg

