#!/usr/bin/env sh

source ./framework.sh

files="portainer.sh"

initOsVars

for FILE in $files
do
  if ! sh "${FILE}"; then
    echo ' -> Failed'
    printf "\\e[31mTests failed\\e[0m\n"
    exit 1
  fi
done

printf "\\e[32mTests successful\\e[0m\n"
