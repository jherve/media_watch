#!/bin/bash
set -euo pipefail

ROOT_DIR=`pwd`
SOURCE_DIR=$ROOT_DIR
BUILD_DIR=$ROOT_DIR/priv/build/

APP_NAME=${APP_NAME?not set}
OS_VERSION=${OS_VERSION?not set}
MIX_ENV=${MIX_ENV-prod}
APP_VERSION=$(cat $SOURCE_DIR/VERSION | tail -1)

DOCKER_DIR=$BUILD_DIR/$OS_VERSION
DOCKER_IMAGE_VERSION=`echo $APP_VERSION | sed "s#+#-#"`
DOCKER_IMAGE_TAG=$APP_NAME-$OS_VERSION:$DOCKER_IMAGE_VERSION

build_image() {
  docker build -t $DOCKER_IMAGE_TAG $DOCKER_DIR
}

build_binary() {
  docker run -e SOURCE_DIR=/app \
             -e MIX_ENV=$MIX_ENV \
             -e DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG \
             -v $ROOT_DIR:/app \
             $DOCKER_IMAGE_TAG \
             /app/priv/build/build.sh
}

build_image
build_binary
