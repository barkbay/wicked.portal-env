#!/bin/bash

set -e

if [ -z "$DOCKER_PREFIX" ]; then
    echo "WARNING: Env var DOCKER_PREFIX not set, assuming haufelexware/wicked."
    export DOCKER_PREFIX="haufelexware/wicked."
fi

if [ -z "$DOCKER_TAG" ]; then
    echo "WARNING: Env var DOCKER_TAG is not set, assuming 'dev'."
    export DOCKER_TAG=dev
fi

git log -1 --decorate=short > git_last_commit
git rev-parse --abbrev-ref HEAD > git_branch

echo "============================================"
echo "Building normal image..."
echo "============================================"

docker pull node:6
docker build -t ${DOCKER_PREFIX}portal-env:${DOCKER_TAG}-onbuild .

echo "============================================"
echo "Building alpine image..."
echo "============================================"

docker pull node:6-alpine
docker build -f Dockerfile-alpine -t ${DOCKER_PREFIX}portal-env:${DOCKER_TAG}-onbuild-alpine .

if [ "$1" = "--push" ]; then

    echo "============================================"
    echo "Logging in to registry..."
    echo "============================================"

    if [ -z "$DOCKER_REGISTRY_USER" ] || [ -z "$DOCKER_REGISTRY_PASSWORD" ]; then
        echo "ERROR: Env vars DOCKER_REGISTRY_USER and/or DOCKER_REGISTRY_PASSWORD not set."
        echo "Cannot push images, exiting."
        exit 1
    fi

    if [ -z "$DOCKER_REGISTRY" ]; then
        echo "WARNING: Env var DOCKER_REGISTRY not set, assuming official docker hub."
        docker login -u ${DOCKER_REGISTRY_USER} -p ${DOCKER_REGISTRY_PASSWORD}
    else
        docker login -u ${DOCKER_REGISTRY_USER} -p ${DOCKER_REGISTRY_PASSWORD} ${DOCKER_REGISTRY}
    fi

    echo "============================================"
    echo "Pushing ${DOCKER_PREFIX}portal-env:${DOCKER_TAG}-onbuild"
    echo "============================================"

    docker push ${DOCKER_PREFIX}portal-env:${DOCKER_TAG}-onbuild

    echo "============================================"
    echo "Pushing ${DOCKER_PREFIX}portal-env:${DOCKER_TAG}-onbuild-alpine"
    echo "============================================"
    
    docker push ${DOCKER_PREFIX}portal-env:${DOCKER_TAG}-onbuild-alpine
else
    if [ ! -z "$1" ]; then
        echo "WARNING: Unknown parameter '$1'; did you mean --push?"
    fi
fi
