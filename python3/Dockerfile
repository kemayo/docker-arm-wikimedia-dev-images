# check=skip=InvalidDefaultArgInFrom
# BASE_IMAGE has no default on purpose. A default would be a second copy of
# the parent tag, which can go stale. build.sh always passes the parent.

# Local extra, not a mirror of an upstream image.
#
# The official dev images have no python3, but the production servers do.
# SyntaxHighlight_GeSHi needs it for its bundled pygmentize script. This
# layer stays separate to keep the mirror images faithful to upstream.
#
# Build once per parent image, and pass the parent in BASE_IMAGE.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN apt-get update && apt-get install -yq python3 \
    && rm -rf /var/lib/apt/lists/*
