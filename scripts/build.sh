#!/usr/bin/env bash

set -o xtrace
set -o pipefail
set -o errexit
# fail on undeclared vars
set -o nounset

__DIR__=$(dirname "$(readlink -f "$0")")

SERVICE=micro
CONTAINER_REGISTRY_NAME=${CONTAINER_REGISTRY_NAME:-quay.io}
CONTAINER_REGISTRY_GROUP=${CONTAINER_REGISTRY_GROUP:-amadev}
GITLAB_CI=${GITLAB_CI:-}
if [ ! -z "$GITLAB_CI" ]; then
    CONTAINER_REGISTRY_GROUP=xpate
fi
IMAGE_NAME="$CONTAINER_REGISTRY_GROUP/$SERVICE"
CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA:-$(git rev-parse --short HEAD)}
TAG1="$CONTAINER_REGISTRY_NAME/$IMAGE_NAME:latest"
TAG2="$CONTAINER_REGISTRY_NAME/$IMAGE_NAME:$CI_COMMIT_SHORT_SHA"
DOCKER_ARGS=${DOCKER_ARGS:-"--network host --pull --cache-from $TAG1"}

docker build ${DOCKER_ARGS} --build-arg service=$SERVICE --tag $TAG1 --tag $TAG2 .
docker push $TAG1
docker push $TAG2
