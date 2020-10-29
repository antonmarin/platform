#!/bin/sh
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v '/home:/home' \
	docker/compose:1.27.4 -f /home/provisioner/ingress/docker-compose.yml up -d
