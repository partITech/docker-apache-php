#!/usr/bin/env bash

makeVersion () {
  PHP_VERSION=$1
  XDEBUG_VERSION=3.1.6
  DEBIAN_VERSION=apache

  if [[ $PHP_VERSION == 7.3 ]]; then
    DEBIAN_VERSION=apache-buster
  fi

  if [[ $PHP_VERSION == 8.1 || $PHP_VERSION == 8.2  ]]; then
    XDEBUG_VERSION=3.2.1
  fi

  if [[ $PHP_VERSION == 8.3 ]]; then
    XDEBUG_VERSION=3.3.1
  fi

  docker build \
  -t devpartitech/php:"${PHP_VERSION}"-apache \
  --build-arg PHP_VERSION="${PHP_VERSION}" \
  --build-arg XDEBUG_VERSION=$XDEBUG_VERSION \
  --build-arg DEBIAN_VERSION=$DEBIAN_VERSION \
  --squash --compress \
  --no-cache .
  ## Push to personal repo on docker.io
  docker push devpartitech/php:"${PHP_VERSION}"-apache
}

#PHP_VERSIONS=(7.2 7.3 7.4 8.0 8.1 8.2 8.3)
PHP_VERSIONS=(8.3)
for PHP_VERSION in "${PHP_VERSIONS[@]}"
do
	makeVersion "$PHP_VERSION"
done