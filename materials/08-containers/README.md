# Containers: companion material

Goes with the **Containers** course on Alfred Learning. The in-page terminal cannot build or run a
container, so the course has you author these files and works the failures as scenarios. Here you
can build and run them.

| File | What it shows |
| --- | --- |
| [app/Dockerfile](app/Dockerfile) | Multi-stage: test in the build stage, ship only the app, run as a non-root user, exec-form `CMD` |
| [app/.dockerignore](app/.dockerignore) | A small build context with no `.env` in it |
| [compose.yaml](compose.yaml) | Two services, a health-gated start, a named volume, a read-only root filesystem, a port bound to localhost only |
| [app/server.js](app/server.js) | A dependency-free web service that exits cleanly on `SIGTERM` |

## Build and run

```bash
cd app
docker build -t alfred-hello:dev .          # the build stage runs the tests; a failing test fails the build
docker run --rm -p 127.0.0.1:8080:8080 alfred-hello:dev
curl -s localhost:8080                       # in another terminal
```

Then with compose, from this folder:

```bash
docker compose up --build -d
docker compose ps                            # "healthy" once the health checks pass
docker compose logs web
docker compose down
```

If Docker says **port is already allocated**, something else on your machine uses 8080. Change the
left-hand number (`-p 127.0.0.1:8081:8080`, or `"127.0.0.1:8081:8080"` in `compose.yaml`) and use
that port instead.

## Things to try, from the course

- **The image size.** `docker image ls alfred-hello`. Change the runtime stage to `FROM node:24` (no
  `-alpine`), rebuild and compare.
- **Who the process runs as.** `docker run --rm alfred-hello:dev id`. Remove `USER node`, rebuild,
  run `id` again.
- **Who receives the stop signal.** With the container running, `docker exec <container> ps` shows
  `node server.js` as PID 1, so `docker stop`'s `SIGTERM` reaches the app and it exits cleanly. Change
  `CMD` to `CMD node server.js; echo "server exited"`, rebuild, and look again: now PID 1 is
  `/bin/sh`, which does not pass the signal on, so the app is killed without the chance to finish
  what it was doing.
  (A single shell-form command often still works, because the shell replaces itself with it; a wrapper
  script or a second command is what breaks it.)
- **Where the data lives.** `docker compose down` keeps the `cache-data` volume; `docker compose down -v`
  deletes it. Which one would you run on a database?
- **A read-only container.** `docker compose exec web touch /app/x` fails. Writing to `/tmp` works,
  because it is a `tmpfs`.
- **Scan it.** `trivy image alfred-hello:dev` (see [06-security](../06-security/)).

The [Kubernetes](../09-kubernetes/) and [CI/CD](../10-cicd/) materials use this same image.
