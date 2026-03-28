#!/bin/bash
set -euo pipefail

REGISTRY=docker-registry.wikimedia.org
DISTRO=bookworm
dateToday=$(date -u +%Y%m%d)
img="${REGISTRY}/${DISTRO}"
imgFull="${img}:${dateToday}"
imgTag="${REGISTRY}/wikimedia-${DISTRO}"
apache2Img="${REGISTRY}/dev/${DISTRO}-apache2"
apache2Tag="1.0.1-arm1"
phpImg="${REGISTRY}/dev/${DISTRO}-php83"
phpTag="1.0.0"
phpFpmImg="${REGISTRY}/dev/${DISTRO}-php83-fpm"
phpFpmTag="1.0.0-arm1"
phpJobRunnerImg="${REGISTRY}/dev/${DISTRO}-php83-jobrunner"
phpJobRunnerTag="1.0.0-arm1"
## Remove old images (ignore errors if images don't exist)
docker rmi "${imgFull}" || true
docker rmi "${img}:latest" || true
docker rmi "${imgTag}:latest" || true
docker rmi "${apache2Img}:${apache2Tag}" || true
docker rmi "${phpImg}:${phpTag}" || true
docker rmi "${phpFpmImg}:${phpFpmTag}" || true
docker rmi "${phpJobRunnerImg}:${phpJobRunnerTag}" || true
## Building Core image
echo "Building Core ${DISTRO} image ${imgFull}"
docker build . -f ${DISTRO}/Dockerfile -t "${imgFull}"
## Tagging Core image
echo "Tagging Core ${DISTRO} image ${img}:latest and ${imgTag}:latest"
docker tag "${imgFull}" "${img}:latest"
docker tag "${imgFull}" "${imgTag}:latest"
## Building Apache2 image
echo "Building Apache2 ${DISTRO} image ${apache2Img}:${apache2Tag}"
docker build . -f apache2/Dockerfile -t "${apache2Img}:${apache2Tag}"
## Building php8.3 image
echo "Building php8.3 image ${phpImg}:${phpTag}"
docker build . -f php83/Dockerfile -t "${phpImg}:${phpTag}"
## Building php8.3 FPM image
echo "Building php8.3 FPM ${DISTRO} image ${phpFpmImg}:${phpFpmTag}"
docker build . -f fpm/Dockerfile -t "${phpFpmImg}:${phpFpmTag}"
## Building php8.3 Job Runner image
echo "Building php8.3 Job Runner ${DISTRO} image ${phpJobRunnerImg}:${phpJobRunnerTag}"
docker build . -f jobrunner/Dockerfile -t "${phpJobRunnerImg}:${phpJobRunnerTag}"

## Remove unused images (ignore errors if images don't exist)
docker rmi "${imgFull}" || true
docker rmi "${img}:latest" || true
docker rmi "${imgTag}:latest" || true
docker rmi "${phpImg}:${phpTag}" || true
