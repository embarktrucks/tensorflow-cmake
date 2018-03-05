#!/usr/bin/env bash
set -e

./build-eigen.sh
cd /usr/cache/$(ls -1 /usr/cache | grep proto)
make install
