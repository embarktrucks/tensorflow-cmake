#!/usr/bin/env bash

./build-eigen.sh
cd /usr/cache/$(ls -1 /usr/cache | grep proto)
make install
