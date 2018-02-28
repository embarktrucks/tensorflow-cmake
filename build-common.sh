#!/usr/bin/env bash
# Common functionality for use in build scripts.

# Prints an error message and exits with an error code of 1
fail () {
    echo -e "${RED}Command failed - script terminated${NO_COLOR}"
    exit 1
}

install_packages () {
    for PKG in ${*}; do
        if ! dpkg -l ${PKG} > /dev/null 2>&1; then
            apt-get -qqy install ${PKG} || fail
        fi
    done
    apt-get update -qqy
}
