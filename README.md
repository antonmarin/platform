# A personal platform for my experiments

## Contributing

### Getting started

- `cp .env.dist .env`
- `make run`

## Usage

- deploy
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
