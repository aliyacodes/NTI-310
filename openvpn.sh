#!/bin/bash
# Based on the tutorial here: https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-centos-7
sudo yum update -y
yum install -y openvpn wget
wget -O /tmp/easyrsa https://github.com/OpenVPN/easy-rsa-old/archive/2.3.3.tar.gz
tar xfz /tmp/easyrsa
mkdir /etc/openvpn/easy-rsa
cp -rf easy-rsa-old-2.3.3/easy-rsa/2.0/* /etc/openvpn/easy-rsa
sudo cp /usr/share/doc/openvpn-2.4.8/sample/sample-config-files/server.conf /etc/openvpn
# vim /etc/openvpn/server.conf
# uncomment push "redirect-gateway def1 bypass-dhcp"
# point to google's dns servers
# push "dhcp-option DNS 8.8.8.8"
# push "dhcp-option DNS 8.8.4.4"
# uncomment:
# user nobody
# group nobody
# topology subnet
# add remote-cert-eku "TLS Web Client Authentication" to the file
# Lastly, OpenVPN strongly recommends that users enable TLS Authenticationn, a cryptographic protocal that ensures secure commun...
# comment out tls-auth ta.key 0 by putting a semicolon in front
# add tls-crypt myvpn.tlsauth
openvpn --genkey --secret /etc/openvpn/myvpn.tlsauth
mkdir /etc/openvpn/easy-rsa/keys
# vim /etc/openvpn/easy-rsa/vars
yum install bind-utils
# our ip's resolve to http://35.222.224.173.bc.googleusercontent.com/
# you can find this using nslookup
# so this becomes our CN
# vim /etc/openvpn/easy-rsa/vars
# export KEY_CN="35.222.224.173.bc.googleusercontent.com"
# export KEY_NAME="server"
# export KEY_OU="College"

cd /etc/openvpn/easy-rsa
source ./vars
./clean-all
./build-ca
# Note, this takes manually pressing enter a couple of times... how to automate...
# so does the below
./build-key-server server
./build-dh
cd /etc/openvpn/easy-rsa/keys
cp dh2048.pem ca.crt server.crt server.key /etc/openvpn
# Each client will also need a certificate in order for the OpenVPN server to authenticate it.
# These keys and certificates will be created on the server and then you will have to copy them over to your clients,
# which we will do in a later step.  It's advised that you generate separate keys and certificates for each client you
# intend to connect to your VPN.

# Build the client cert
cd /etc/openvpn/easy-rsa
./build-key client
# press enter and y to certify the cert
cp /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf
firewall-cmd --get-active-zones
firewall-cmd --zone=trusted --add-service openvpn
firewall-cmd --zone=trusted --add-service openvpn --permanent
firewall-cmd --list-services --zone=trusted
# at this point we have to open tcp and udp to port 1194 on google cloud firewall
firewall-cmd --add-masquerade
firewall-cmd --permanent --add-masquerade
firewall-cmd --query-masquerade 
SHARK=$(ip route 8.8.8.8 | awk 'NR==1 {print $(NF-2)}')
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s 10.8.0.0/24 -o $SHARK -j MASQUERADE
firewall-cmd --reload
# vim /etc/sysctl.conf
# put in net.ipv4.ip_forward = 1
# this can be echo'ed in automation
systemctl restart network.service
systemctl -f enable openvpn@server.service
systemctl start openvpn@server.service
systemctl status openvpn@server.service
# Find the following on the server for your client:
# /etc/openvpn/easy-rsa/keys/ca.crt
# /etc/openvpn/easy-rsa/keys/client.crt
# /etc/openvpn/easy-rsa/keys/client.key
# /etc/openvpn/myvpn.tlsauth
mkdir /tmp/client
cp /etc/openvpn/easy-rsa/keys/ca.crt /tmp/client
cp /etc/openvpn/easy-rsa/keys/client.crt /tmp/client
cp /etc/openvpn/easy-rsa/keys/client.key /tmp/client
cp /etc/openvpn/myvpn.tlsauth /tmp/client
tar cvf client.tar client/
