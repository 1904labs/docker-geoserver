#!/bin/sh -x

case $* in
  *--test*)
    BUILD_DATE=$(date -u +'%Y-%m-%d')
    VCS_REF=test
    BUILD_VERSION=test
    ;;
  *)
    BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    VCS_REF=$(git rev-parse --short --verify HEAD)
    BUILD_VERSION=$(git describe --exact-match --tags ${VCS_REF})
    ;;
esac

docker build . \
  --build-arg BUILD_DATE=${BUILD_DATE} \
  --build-arg VCS_REF=${VCS_REF} \
  --build-arg BUILD_VERSION=${BUILD_VERSION} \
  --tag "1904labs/geoserver:${BUILD_VERSION}"

if [ "$BUILD_VERSION" != "test" ]; then
  docker tag "1904labs/geoserver:${BUILD_VERSION}" "1904labs/geoserver:latest"
fi
