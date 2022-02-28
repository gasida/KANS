#!/usr/bin/env bash

cat <<EOT> /etc/netplan/50-vagrant.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
      - 192.168.10.254/24
      routes:
      - to: 172.16.0.0/24
        via: 192.168.10.10
      - to: 172.16.1.0/24
        via: 192.168.10.101
      - to: 172.16.2.0/24
        via: 192.168.10.102
    enp0s9:
      addresses:
      - 192.168.20.254/24
EOT
netplan apply