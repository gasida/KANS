#!/usr/bin/env bash

echo ">>>> BGP (Quagga) Config Start <<<<"
echo "[TASK 1] Install Quagga"
apt-get install quagga -y >/dev/null 2>&1

echo "[TASK 2] Config Quagga"
# quagga logging
mkdir /var/log/quagga
chown quagga:quagga /var/log/quagga

# quagga config
cat <<EOF > /etc/quagga/zebra.conf
hostname zebra
password zebra
enable password zebra
!
log file /var/log/quagga/zebra.log
!
line vty
EOF
systemctl enable zebra >/dev/null 2>&1 && systemctl start zebra

# download bgp script
curl -s -o /root/bgp.sh https://raw.githubusercontent.com/gasida/NDKS/main/8/bgp.sh

echo ">>>> BGP (Quagga) Config End <<<<"
