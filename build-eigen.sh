#!/usr/bin/env bash
# Install eigen
# eigen.sh install <tensorflow-root> [<install-dir> <download-dir>]

source $SCRIPT_DIR/build-common.sh

sudo apt-get install libblas-dev liblapack-dev

${SCRIPT_DIR}/eigen.sh install "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}" "${CACHE_DIR}"
