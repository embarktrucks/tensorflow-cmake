#!/usr/bin/env bash
# Compiles and installs bazel.

source $SCRIPT_DIR/build-common.sh

BAZEL_VER=0.5.4
BAZEL_DEB=bazel_${BAZEL_VER}-linux-x86_64.deb
echo "BAZEL_DEB $BAZEL_DEB"
echo  https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/${BAZEL_DEB} -O ${CACHE_DIR}/${BAZEL_DEB}
if ! dpkg -l bazel > /dev/null 2>&1; then
  if [ ! -e ${BAZEL_DEB} ]; then
    wget --quiet --no-check-certificate https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/${BAZEL_DEB} -O ${SCRIPT_DIR}/${BAZEL_DEB} || fail
  fi
  sudo dpkg -i ${SCRIPT_DIR}/${BAZEL_DEB} || fail
fi
