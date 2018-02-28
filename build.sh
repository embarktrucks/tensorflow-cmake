#!/usr/bin/env bash
#
# Follow https://github.com/cjweeks/tensorflow-cmake
SCRIPT_DIR="$(cd "$(dirname "${0}")"; pwd)"
RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"
TENSORFLOW_COMMIT="23da21150d988f7cf5780488f24adbb116675586"

################################### Functions ###################################

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

install_bazel () {
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
}

################################### Script ###################################

# install javajdk
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update -qq

# Need to jump past the interactivity requirement in the java installer
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections

install_packages oracle-java8-installer

if [ ${#} -lt 2 ]; then
    echo "Usage: ${0} <build-dir> <install-dir>"
    exit 0
fi

# create the directorie if they don't already exist
mkdir -p "${1}" || fail
mkdir -p "${2}" || fail

BUILD_DIR=$(readlink -f "${1}")
INSTALL_DIR=$(readlink -f "${2}")
CACHE_DIR=${INSTALL_DIR}/cache

echo "INSTALL DIR: $INSTALL_DIR"
echo "BUILD DIR: $BUILD_DIR"

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

install_bazel || fail

####################################################################
# Download and compile tensorflow from github
# Directory will be:
# $BUILD_DIR
#     - tensorflow-cmake
#     - tensorflow-github
#
mkdir -p ${INSTALL_DIR}/{include,lib,bin,share,cache}
mkdir -p ${INSTALL_DIR}/share/cmake/Modules
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

cd ${BUILD_DIR}

if [ ! -e ${CACHE_DIR}/tensorflow-github.tgz ]; then
    git clone https://github.com/tensorflow/tensorflow tensorflow-github || fail
    tar czf ${CACHE_DIR}/tensorflow-github.tgz tensorflow-github || fail
else
    cp ${CACHE_DIR}/tensorflow-github.tgz . || fail
    tar xzf ./tensorflow-github.tgz || fail
fi


####################################################################
# This specifies a new build rule, producing libtensorflow_all.so,
# that includes all the required dependencies for integration with
# a C++ project.
# Build the shared library and copy it to $INSTALLDIR
TF_ROOT=${BUILD_DIR}/tensorflow-github
cd $TF_ROOT
# check out the appropriate commit
git reset --hard 23da21150d988f7cf5780488f24adbb116675586
cat <<EOF >> tensorflow/BUILD
# Added build rule
cc_binary(
    name = "libtensorflow_all.so",
    linkshared = 1,
    linkopts = ["-Wl,--version-script=tensorflow/tf_version_script.lds"], # if use Mac remove         this line
    deps = [
       "//tensorflow/c:c_api",
       "//tensorflow/cc:cc_ops",
       "//tensorflow/cc:client_session",
       "//tensorflow/cc:scope",
       "//tensorflow/core:framework_internal",
       "//tensorflow/core:tensorflow",
    ],
)

EOF

# Taken from https://gist.github.com/PatWie/0c915d5be59a518f934392219ca65c3d
export PYTHON_BIN_PATH=/usr/bin/python2.7
export PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
export PYTHONPATH=${TF_ROOT}/lib
export PYTHON_ARG=${TF_ROOT}/lib
export CUDA_TOOLKIT_PATH=/usr/local/cuda-8.0
export CUDNN_INSTALL_PATH=/usr/local/cuda

export TF_NEED_GCP=0
export TF_NEED_CUDA=1
export TF_CUDA_VERSION="$($CUDA_TOOLKIT_PATH/bin/nvcc --version | sed -n 's/^.*release \(.*\),.*/\1/p')"
export TF_CUDA_COMPUTE_CAPABILITIES=6.1
export TF_NEED_HDFS=0
export TF_NEED_OPENCL=0
export TF_NEED_JEMALLOC=1
export TF_ENABLE_XLA=0
export TF_NEED_VERBS=0
export TF_CUDA_CLANG=0
export TF_CUDNN_VERSION="$(sed -n 's/^#define CUDNN_MAJOR\s*\(.*\).*/\1/p' $CUDNN_INSTALL_PATH/include/cudnn.h)"
export TF_NEED_MKL=0
export TF_DOWNLOAD_MKL=0
export TF_NEED_MPI=0

export GCC_HOST_COMPILER_PATH=$(which gcc)
export CC_OPT_FLAGS="-march=native"
./configure

#expect configure_script.exp
#./configure < configure_answers.txt
bazel build --config opt --config cuda tensorflow:libtensorflow_all.so || fail

# copy the library to the install directory
cp bazel-bin/tensorflow/libtensorflow_all.so ${INSTALL_DIR}/lib || fail

# Copy the source to $INSTALL_DIR/include/google and remove unneeded items:
mkdir -p ${INSTALL_DIR}/include/google/tensorflow
cp -r tensorflow ${INSTALL_DIR}/include/google/tensorflow/
find ${INSTALL_DIR}/include/google/tensorflow/tensorflow -type f  ! -name "*.h" -delete

# Copy all generated files from bazel-genfiles:
cp  bazel-genfiles/tensorflow/core/framework/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/framework
cp  bazel-genfiles/tensorflow/core/kernels/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/kernels
cp  bazel-genfiles/tensorflow/core/lib/core/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/lib/core
cp  bazel-genfiles/tensorflow/core/protobuf/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/protobuf
cp  bazel-genfiles/tensorflow/core/util/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/util
cp  bazel-genfiles/tensorflow/cc/ops/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/cc/ops

# Copy the third party directory:
cp -r third_party ${INSTALL_DIR}/include/google/tensorflow/
rm -r ${INSTALL_DIR}/include/google/tensorflow/third_party/py

# Note: newer versions of TensorFlow do not have the following directory
rm -rf ${INSTALL_DIR}/include/google/tensorflow/third_party/avro

# Install eigen
# eigen.sh install <tensorflow-root> [<install-dir> <download-dir>]
${SCRIPT_DIR}/eigen.sh install "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}" "${INSTALL_DIR}/cache"
# eigen.sh generate installed <tensorflow-root> [<cmake-dir> <install-dir>]
#${SCRIPT_DIR}/eigen.sh generate external "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}/share/cmake" "${INSTALL_DIR}"

# Install protobuf
# protobuf.sh install <tensorflow-root> [<cmake-dir>]
${SCRIPT_DIR}/protobuf.sh install "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}" "${INSTALL_DIR}/cache"
# protobuf.sh generate installed <tensorflow-root> [<cmake-dir> <install-dir>]
#${SCRIPT_DIR}/protobuf.sh generate installed "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}/share/cmake" "${INSTALL_DIR}"
