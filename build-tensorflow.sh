#!/usr/bin/env bash
# Download and compile tensorflow from GitHub

source $SCRIPT_DIR/build-common.sh

####################################################################
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
ls -lah
TF_ROOT=$(pwd)/tensorflow-github
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

