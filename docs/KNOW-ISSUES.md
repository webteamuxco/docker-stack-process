# KNOWN ISSUES

### Trivy tmp cache

example:

``` shell
2026-10-19T10:06:18Z    FATAL   Fatal error     run error: init error: DB error: failed to download vulnerability DB: OCI artifact error: failed to download vulnerability DB: failed to download artifact from mirror.gcr.io/aquasec/trivy-db:2: oci download error: download error: failed to download /tmp/trivy-662808269/oci-download-3539390311/db.tar.gz: open /tmp/.cache/trivy/db/trivy.db: permission denied
```

resolution:

get volume cache filter name:

```shell
 docker volume ls --filter name=trivy
```

and replace {{myProject}} with the good value

```shell
docker run --rm \
  -v {{myProject}}_trivy_cache:/cache \
  alpine:3.22 \
  chown -R "${HOST_UID:-1000}:${HOST_GID:-1000}" /cache
```

bazouka method:

you can clear all volume for cache trivy

```shell
docker volume ls --filter name=trivy --format '{{.Name}}' |
while read -r volume; do
  echo "Corrects permissions : $volume"
  docker run --rm \
    -v "$volume:/cache" \
    alpine:3.22 \
    chown -R "${HOST_UID:-1000}:${HOST_GID:-1000}" /cache
done
```