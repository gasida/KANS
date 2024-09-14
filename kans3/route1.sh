#!/usr/bin/env bash

IP=$(ip -br -4 addr | grep enp0s8 | awk '{print $3}')

cat <<EOT> /etc/netplan/50-vagrant.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
      - $IP
      routes:
      - to: 192.168.20.0/24
        via: 192.168.10.254
EOT
chmod 600 /etc/netplan/50-vagrant.yaml
netplan apply