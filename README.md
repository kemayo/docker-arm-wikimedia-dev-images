# Wikimedia dev debian images with Dockerfiles
This tool and script helps to create arm/(Mac M1 compatible) images for the developer environment on the Wikimedia framework. Which helps with performance and debugging on arm machines.

The images mirror the upstream ones from
[repos/releng/dev-images](https://gitlab.wikimedia.org/repos/releng/dev-images).
Tags keep the upstream version and add an `-arm1` suffix. The main difference:
upstream installs PHP from `apt.wikimedia.org`, which has no arm64 packages, so
these images install PHP from [Sury](https://packages.sury.org/php/) instead.

The build also makes `-python3` variants of the FPM and job runner images.
Upstream installs no python3, but the production servers have it, and
SyntaxHighlight_GeSHi needs it for its bundled `pygmentize` script. The
python3 layer is a separate image, so the mirrors stay faithful to upstream.
Use the plain tags if you do not want it.

## Keeping up with upstream

Most files in `files/` are copies of upstream files, and the tags in
`build.sh` come from the upstream changelogs. `check-drift.sh` compares both
with the upstream commit in `upstream.pin`:

```shell
./check-drift.sh
```

It reports local copies that no longer match the pin, upstream changes made
after the pin, and image versions that upstream bumped. It exits non-zero
when it finds drift. Apply the changes by hand, then move the pin:

```shell
./check-drift.sh --update-pin
```

Three files stay different on purpose: the FPM pool size and error log in
`www.conf`, and the non-root run user in `apache2.conf` and the Apache
`entrypoint.sh`. The script lists upstream changes to these for review
instead of expecting them to match.

## How to use Arm Docker images in your project

- Run the following to create local images

    ```shell
    ./build.sh
    ```

- Create `docker-compose.override.yml` file in your core project and put the following in:
    ```yaml
    services:
      mediawiki:
        image: docker-registry.wikimedia.org/dev/bookworm-php85-fpm:1.0.0-arm1-python3
      mediawiki-web:
        image: docker-registry.wikimedia.org/dev/bookworm-apache2:1.0.1-s3-arm1
      mediawiki-jobrunner:
        image: docker-registry.wikimedia.org/dev/bookworm-php85-jobrunner:1.0.0-arm1-python3
    ```

- Shutdown the current containers:
  ```shell
  docker-compose down
  ```

- Start the containers:
  ```shell
  docker-compose up -d
  ```
