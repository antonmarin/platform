#!/usr/bin/env bash
# draft
docker-compose down
datestamp=$(date +%m-%d-%Y)
backup_dir="/home/<user>/vw-backups"
zip -9 -r "${backup_dir}/${datestamp}.zip" /opt/vw-data*
scp -i ~/.ssh/id_rsa "${backup_dir}/${datestamp}.zip" user@<REMOTE_IP>:~/vw-backups/
docker-compose up -d

# clean
# cd ~/backups || exit
#  #find . -type f -name '*.zip' ! -mtime -1 -exec rm {} +

