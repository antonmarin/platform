#!/usr/bin/env sh
set -eu

sudo sed -i '/^[#]\?AllowTcpForwarding/c\AllowTcpForwarding yes' /etc/ssh/sshd_config
sudo sed -i '/^[#]\?GatewayPorts/c\GatewayPorts yes' /etc/ssh/sshd_config

cat /etc/ssh/sshd_config | grep AllowTcpForwarding
cat /etc/ssh/sshd_config | grep GatewayPorts
sudo systemctl restart sshd
