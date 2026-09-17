# Wikimedia dev debian images with Dockerfiles
This tool and script helps to create arm/(Mac M1 compatible) images for the developer environment on the Wikimedia framework. Which helps with performance and debugging on arm machines.

The images mirror the upstream ones from
[repos/releng/dev-images](https://gitlab.wikimedia.org/repos/releng/dev-images).
Tags keep the upstream version and add an `-arm1` suffix. The main difference:
upstream installs PHP from `apt.wikimedia.org`, which has no arm64 packages, so
these images install PHP from [Sury](https://packages.sury.org/php/) instead.

## How to use Arm Docker images in your project

- Run the following to create local images

    ```shell
    ./build.sh
    ```

- Create `docker-compose.override.yml` file in your core project and put the following in:
    ```yaml
    services:
      mediawiki:
        image: docker-registry.wikimedia.org/dev/bookworm-php85-fpm:1.0.0-arm1
      mediawiki-web:
        image: docker-registry.wikimedia.org/dev/bookworm-apache2:1.0.1-s3-arm1
      mediawiki-jobrunner:
        image: docker-registry.wikimedia.org/dev/bookworm-php85-jobrunner:1.0.0-arm1
    ```

- Shutdown the current containers:
  ```shell
  docker-compose down
  ```

- Start the containers:
  ```shell
  docker-compose up -d
  ```
