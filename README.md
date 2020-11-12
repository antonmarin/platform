# A personal platform for my experiments

## Contributing

### Concept

- `Application` is a separated folder in `platform_apps/` or `deploy_apps`
- All applications files uploads to `/var/apps`
- Every application with `docker-compose.yml` would be started with `docker-compose up -d`

### Getting started

- `cp .env.dist .env`
- `make run`

### Notes

- To get service logs `journalctl -u service-name.service`
- To start/stop service `systemctl start/stop service-name.service`

## Usage

- [routing](https://doc.traefik.io/traefik/routing/providers/docker/)
- [middlewares](https://doc.traefik.io/traefik/middlewares/overview/)
- use `ingress` external network to enable ingress routing to your container.

### Examples

Docker-compose

```
services:
  nginx:
    image: "nginx:latest"
    labels:
      - "traefik.http.routers.index.rule=Host(`${INDEX_HOSTNAME}`)"
      - "traefik.http.routers.myrouter.rule=PathPrefix(`/test`)" \
      - "traefik.http.routers.myrouter.middlewares=myrouter-stripprefix" \
      - "traefik.http.middlewares.myrouter-stripprefix.stripprefix.prefixes=/test,/test/" \

    networks:
      - ingress
    environment:
      - INDEX_HOSTNAME
    volumes:
      - ./conf.d:/etc/nginx/conf.d

networks:
  ingress:
    external: true
```

Docker run

```
  docker run \
    -l 'traefik.http.routers.myrouter.rule=PathPrefix(`/test`)' \
    -l 'traefik.http.routers.myrouter.middlewares=myrouter-stripprefix' \
    -l 'traefik.http.middlewares.myrouter-stripprefix.stripprefix.prefixes=/test,/test/' \
    --network=ingress \
    nginx
```
