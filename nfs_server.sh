#!/bin/bash

yum install -y nfs-utils
mkdir /var/nfsshare
mkdir /var/nfsshare/devstuff
mkdir /var/nfsshare/testing
mkdir /var/nfsshare/home_dirs
chmod -R 777 /var/nfsshare/
systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap
cd /var/nfsshare/

echo "/var/nfsshare/home_dirs *(rw,sync,no_all_squash)
/var/nfsshare/devstuff *(rw,sync,no_all_squash)
/var/nfsshare/testing *(rw,sync,no_all_squash)" >> /etc/exports

systemctl restart nfs-server
#install net tools to get ifconfig
yum -y install net-tools

# use ifconfig to find your IP address, you will use this for the client.

# From the client (ubuntu machine)

apt-get install nfs-client

showmount -e 10.128.0.7 # where $ipaddress is the ip of your nfs server
mkdir /mnt/test
echo "10.128.0.7:/var/nfsshare/testing			/mnt/test     nfs defaults 0 0" >> /etc/fstab
mount -a
# *profit*
