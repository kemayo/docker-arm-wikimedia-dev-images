#!/bin/bash
set -euo pipefail

REGISTRY=docker-registry.wikimedia.org
DISTRO=bookworm
dateToday=$(date -u +%Y%m%d)
img="${REGISTRY}/${DISTRO}"
imgFull="${img}:${dateToday}"
imgTag="${REGISTRY}/wikimedia-${DISTRO}"
# Tags track the upstream dev-images releases, plus an "-arm1" suffix.
suryImg="${REGISTRY}/dev/${DISTRO}-php-sury"
suryTag="1.0.1-s4-arm1"
apache2Img="${REGISTRY}/dev/${DISTRO}-apache2"
apache2Tag="1.0.1-s3-arm1"
phpImg="${REGISTRY}/dev/${DISTRO}-php85"
phpTag="1.0.0-arm1"
phpFpmImg="${REGISTRY}/dev/${DISTRO}-php85-fpm"
phpFpmTag="1.0.0-arm1"
phpJobRunnerImg="${REGISTRY}/dev/${DISTRO}-php85-jobrunner"
phpJobRunnerTag="1.0.0-arm1"
# Suffix for the local python3 images, derived from the mirrors above.
python3Suffix="-python3"
## Remove old images (silently ignore if images don't exist)
docker rmi "${imgFull}" 2>/dev/null || true
docker rmi "${img}:latest" 2>/dev/null || true
docker rmi "${imgTag}:latest" 2>/dev/null || true
docker rmi "${suryImg}:${suryTag}" 2>/dev/null || true
docker rmi "${apache2Img}:${apache2Tag}" 2>/dev/null || true
docker rmi "${phpImg}:${phpTag}" 2>/dev/null || true
docker rmi "${phpFpmImg}:${phpFpmTag}" 2>/dev/null || true
docker rmi "${phpJobRunnerImg}:${phpJobRunnerTag}" 2>/dev/null || true
docker rmi "${phpFpmImg}:${phpFpmTag}${python3Suffix}" 2>/dev/null || true
docker rmi "${phpJobRunnerImg}:${phpJobRunnerTag}${python3Suffix}" 2>/dev/null || true
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
## Building Sury APT image
echo "Building Sury APT ${DISTRO} image ${suryImg}:${suryTag}"
docker build . -f php-sury/Dockerfile -t "${suryImg}:${suryTag}"
## Building php8.5 image
echo "Building php8.5 image ${phpImg}:${phpTag}"
docker build . -f php85/Dockerfile -t "${phpImg}:${phpTag}"
## Building php8.5 FPM image
echo "Building php8.5 FPM ${DISTRO} image ${phpFpmImg}:${phpFpmTag}"
docker build . -f fpm/Dockerfile -t "${phpFpmImg}:${phpFpmTag}"
## Building php8.5 Job Runner image
echo "Building php8.5 Job Runner ${DISTRO} image ${phpJobRunnerImg}:${phpJobRunnerTag}"
docker build . -f jobrunner/Dockerfile -t "${phpJobRunnerImg}:${phpJobRunnerTag}"
## Building the python3 variants of the FPM and Job Runner images
echo "Building python3 variant ${phpFpmImg}:${phpFpmTag}${python3Suffix}"
docker build . -f python3/Dockerfile \
    --build-arg BASE_IMAGE="${phpFpmImg}:${phpFpmTag}" \
    -t "${phpFpmImg}:${phpFpmTag}${python3Suffix}"
echo "Building python3 variant ${phpJobRunnerImg}:${phpJobRunnerTag}${python3Suffix}"
docker build . -f python3/Dockerfile \
    --build-arg BASE_IMAGE="${phpJobRunnerImg}:${phpJobRunnerTag}" \
    -t "${phpJobRunnerImg}:${phpJobRunnerTag}${python3Suffix}"

## Remove unused images (silently ignore if images don't exist)
docker rmi "${imgFull}" 2>/dev/null || true
docker rmi "${img}:latest" 2>/dev/null || true
docker rmi "${imgTag}:latest" 2>/dev/null || true
docker rmi "${suryImg}:${suryTag}" 2>/dev/null || true
docker rmi "${phpImg}:${phpTag}" 2>/dev/null || true
