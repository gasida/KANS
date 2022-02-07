#!/usr/bin/env bash

cat <<EOT>> /etc/netplan/50-vagrant.yaml
      routes:
      - to: 192.168.10.0/24
        via: 192.168.20.254
EOT
netplan apply