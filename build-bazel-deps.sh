#!/usr/bin/env bash
# Installs all of the dependencies necessary for compiling bazel.

SCRIPT_DIR="$(cd "$(dirname "${0}")"; pwd)"
source $SCRIPT_DIR/build-common.sh

# install required packages
install_packages \
  autoconf \
  automake \
  bash-completion \
  build-essential \
  curl \
  expect \
  g++ \
  git \
  libcupti-dev \
  libtool \
  make \
  openjdk-8-jdk \
  pkg-config \
  python-dev \
  python-numpy \
  python-wheel \
  swig \
  unzip \
  wget \
  zip \
  zlib1g-dev \
  || fail

# For some reason doing install_packages for this doesn't work. bazel requires it, so
# we try again here. Might be a good TODO in the future to look into this.
apt-get install -qqy bash-completion
