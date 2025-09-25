# Getting started

- Создаём пользователя, например:
  `useradd -r -s /bin/sh -d /var/lib/tunnel -m -c "SSH Tunnel User" tunnel`
- Если нет автосоздания домашних папок, то:
  `sudo mkdir -p /volume1/homes/tunnel`
  `sudo chown tunnel:users /volume1/homes/tunnel`
  `sudo chmod 700 /volume1/homes/tunnel`
- Создаем ему ключ без пароля
  -f /volume1/homes/tunnel/.ssh/id_ed25519
  `sudo mkdir -p /volume1/homes/tunnel/.ssh`
  `sudo chmod 700 /volume1/homes/tunnel/.ssh`
  `sudo chown tunnel:users /volume1/homes/tunnel/.ssh`
  `sudo -u tunnel ssh-keygen -t ed25519  -N ""`
- Устанавливаем доступ по ключу на удаленный сервер
  `sudo -u tunnel ssh-copy-id -i /volume1/homes/tunnel/.ssh/id_ed25519.pub user@remote.server.com`
- разместить `ssh-tunnel.service` в `/etc/systemd/system/ssh-tunnel.service`
- `sudo systemctl daemon-reload`
- `sudo systemctl enable ssh-tunnel@tunnel.service`
- `sudo systemctl start ssh-tunnel@tunnel.service`
- `sudo systemctl status ssh-tunnel@tunnel.service`
