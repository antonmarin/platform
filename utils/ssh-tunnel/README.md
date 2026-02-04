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
- регаем ключ удаленного сервера знакомым
  `sudo -u tunnel ssh user@remote.server.com ` and accept
- Устанавливаем доступ по ключу на удаленный сервер вручную или
  `sudo -u tunnel ssh-copy-id -i /volume1/homes/tunnel/.ssh/id_ed25519.pub user@remote.server.com`
- разместить `tunnel.sh` в `/volume1/homes/tunnel`
- разместить `ssh-tunnel@.service` в `/usr/lib/systemd/system/ssh-tunnel@.service`
- `sudo systemctl daemon-reload`
- убедиться что на remote.server.com разрешен TcpForwarding скриптом `enable-ssh-tunnels.sh`
- `sudo systemctl enable ssh-tunnel@your-instance.service`
- `sudo systemctl start ssh-tunnel@your-instance.service`
- `sudo systemctl status ssh-tunnel@your-instance.service`
- логи в `sudo journalctl -u ssh-tunnel@your-instance.service -f`
- для запуска нескольких именуй переменные в tunnel.env `${your-instance}_TUNNEL` и `${your-instance}_CONNECTION`
