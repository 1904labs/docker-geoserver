#!/bin/sh

exec docker build . \
  --tag "1904labs/geoserver:test"
