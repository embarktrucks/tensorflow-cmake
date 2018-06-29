#!/usr/bin/env bash
#
# Follow https://github.com/cjweeks/tensorflow-cmake
SCRIPT_DIR="$(cd "$(dirname "${0}")"; pwd)"
RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"
TENSORFLOW_COMMIT="f09aaf0dd33869253020b095d7c44840d1b430fe"

################################### Functions ###################################

source $SCRIPT_DIR/build-common.sh

################################### Script ###################################

# Installs the JDK.
. $SCRIPT_DIR/build-openjdk.sh

if [ ${#} -lt 2 ]; then
    echo "Usage: ${0} <build-dir> <install-dir>"
    exit 0
fi

# create the directories if they don't already exist
mkdir -p "${1}" || fail
mkdir -p "${2}" || fail

BUILD_DIR=$(readlink -f "${1}")
INSTALL_DIR=$(readlink -f "${2}")
CACHE_DIR=${INSTALL_DIR}/cache

echo "INSTALL DIR: $INSTALL_DIR"
echo "BUILD DIR: $BUILD_DIR"

# Installs all of the dependencies necessary for compiling bazel.
. $SCRIPT_DIR/build-bazel-deps.sh || fail

# Compiles and installs bazel.
. $SCRIPT_DIR/build-bazel.sh || fail

# Download and compile tensorflow from GitHub
. $SCRIPT_DIR/build-tensorflow.sh || fail

# Install eigen
# eigen.sh install <tensorflow-root> [<install-dir> <download-dir>]
. $SCRIPT_DIR/build-eigen.sh || fail

# Install protobuf
. $SCRIPT_DIR/build-protobuf.sh || fail
