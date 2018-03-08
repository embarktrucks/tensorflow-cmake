#!/usr/bin/env bash
# Installs the JDK.

SCRIPT_DIR="$(cd "$(dirname "${0}")"; pwd)"
source $SCRIPT_DIR/build-common.sh

# install javajdk
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update -qq

# Need to jump past the interactivity requirement in the java installer
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections

install_packages oracle-java8-installer
