# A personal platform for my experiments

## Contributing

### Concept

- `Application` is a separated folder in `platform_apps/` or `deploy_apps`
- All applications files uploads to `/var/apps`
- Every application with `docker-compose.yml` would be started with `docker-compose up -d`

### Getting started

- `cp .env.dist .env`
- `make run`

## Usage

- [routing](https://doc.traefik.io/traefik/routing/providers/docker/)
- [middlewares](https://doc.traefik.io/traefik/middlewares/overview/)

Example
```
  docker run \
    -l 'traefik.http.routers.myrouter.rule=PathPrefix(`/test`)' \
    -l 'traefik.http.routers.myrouter.middlewares=myrouter-stripprefix' \
    -l 'traefik.http.middlewares.myrouter-stripprefix.stripprefix.prefixes=/test,/test/' \
    nginx
```
