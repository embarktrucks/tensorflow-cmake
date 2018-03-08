#!/usr/bin/env bash
# Install protobuf
# protobuf.sh install <tensorflow-root> [<cmake-dir>]

source $SCRIPT_DIR/build-common.sh

${SCRIPT_DIR}/protobuf.sh install "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}" "${INSTALL_DIR}/cache"
