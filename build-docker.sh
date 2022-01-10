#!/usr/bin/env bash
#
# Builds the docker backup service

set -euo pipefail

tag=${1:-dev}
dockerRepo=kaiede/rpilight
dockerBaseTag=$dockerRepo:${tag}

arch=`arch`
if [ "$arch" == "x86_64" ]; then
    arch=amd64
fi
if [ "$arch" == "aarch64" ]; then
    arch=arm64
fi

dockerTag=$dockerRepo:${tag}-${arch}

docker build . -f Docker/Dockerfile \
    -t $dockerTag \
    --build-arg ARCH=${arch}
