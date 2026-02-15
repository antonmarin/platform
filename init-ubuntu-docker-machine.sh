#!/usr/bin/env sh
set -eu

sudo apt update
sudo apt install ca-certificates curl gnupg

# Add GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://127.0.0.1:2375"]
}
EOF

sudo mkdir /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null <<EOF
[Service]
# дополнить/заменить параметры запуска
# (systemd объединяет/перезаписывает по правилам)
ExecStart=
ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
EOF

sudo sed -i '/^[#]\?AllowTcpForwarding/c\AllowTcpForwarding yes' /etc/ssh/sshd_config
sudo sed -i '/^[#]\?GatewayPorts/c\GatewayPorts yes' /etc/ssh/sshd_config
sshd -T | grep -E "allowtcpforwarding|gatewayports"

sudo systemctl daemon-reload
sudo systemctl restart docker

