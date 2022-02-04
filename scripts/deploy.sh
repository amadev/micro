#!/usr/bin/env bash

set -o xtrace
set -o pipefail
set -o errexit
# fail on undeclared vars
set -o nounset

__DIR__=$(dirname "$(readlink -f "$0")")

SERVICE=micro
HELM_CHART_REPO=https://github.com/micro/helm.git
INFRA_PATH="$PWD/x-infra"
HELM_CHART_PATH=$INFRA_PATH/helm-charts/xpate/${SERVICE}
INFRA_REPO=git@gitlab.com:xpate/x-infra.git
CI_PROJECT_NAME=${CI_PROJECT_NAME:-$SERVICE}
CONTAINER_REGISTRY_NAME=${CONTAINER_REGISTRY_NAME:-quay.io}
CONTAINER_REGISTRY_GROUP=${CONTAINER_REGISTRY_GROUP:-amadev}
GITLAB_CI=${GITLAB_CI:-}
if [ ! -z "$GITLAB_CI" ]; then
    CONTAINER_REGISTRY_GROUP=xpate
fi
IMAGE_NAME="$CONTAINER_REGISTRY_GROUP/$SERVICE"
CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA:-$(git rev-parse --short HEAD)}
HELM_VALUES_FILE=${HELM_VALUES_FILE:-values_test.yaml}
FULL_IMAGE_NAME="$CONTAINER_REGISTRY_NAME/$IMAGE_NAME"

rm -rf $INFRA_PATH
git clone --depth 1 $INFRA_REPO $INFRA_PATH
cd $INFRA_PATH
rm -rf ${HELM_CHART_PATH}_git
git clone --depth 1 $HELM_CHART_REPO ${HELM_CHART_PATH}_git
cp -R ${HELM_CHART_PATH}_git/charts/micro ${HELM_CHART_PATH}
rm -rf ${HELM_CHART_PATH}_git
cat << EOF > $HELM_CHART_PATH/$HELM_VALUES_FILE
image:
  repo: $FULL_IMAGE_NAME
  tag: $CI_COMMIT_SHORT_SHA
EOF
git status --porcelain
git add $HELM_CHART_PATH && git commit -m "${CI_PROJECT_NAME} new version ${CI_COMMIT_SHORT_SHA}"
if [ ! -z "$GITLAB_CI" ]; then
    git push origin master
fi
