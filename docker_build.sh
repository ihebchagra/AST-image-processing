#!/bin/bash
set -e

# Get the source directory from the first argument
ASTIMP_SRC_DIR=$1
if [ -z "$ASTIMP_SRC_DIR" ]; then
    echo "Error: ASTIMP_SRC_DIR not provided. Usage: bash docker_build.sh <path_to_astimp_source>"
    exit 1
fi

# Change to the source directory for building
cd "$ASTIMP_SRC_DIR"

echo "--- Building C++ library ---"
# Clean and create build directory for a fresh build
rm -rf build
mkdir build
cd build
cmake ..
make
cd ..

# Copy libastimp.so to python-module for auditwheel to find
echo "--- Copying libastimp.so to python-module ---"
cp build/astimplib/libastimp.so python-module/

echo "--- Building Python wheel ---"
cd python-module
# Clean previous build artifacts
rm -rf build dist
python3 setup.py bdist_wheel

# Manually set RPATH on the generated .so file
echo "--- Setting RPATH on astimp.cpython-313-x86_64-linux-gnu.so ---"
GENERATED_SO_PATH=$(find build/lib.linux-x86_64-*/ -name "astimp*.so")
# Get the absolute path to build/astimplib relative to the current working directory inside the container
ASTIMP_LIB_ABS_PATH=$(pwd)/../build/astimplib
patchelf --set-rpath "$ASTIMP_LIB_ABS_PATH" "$GENERATED_SO_PATH"

# --- Skipping auditwheel as per user's request ---
echo "--- Skipping auditwheel repair as requested ---"

# Install the built wheel into the virtual environment for use within the container
echo "--- Installing the built wheel into the container's environment ---"
UNREPAIRED_WHEEL_FILE=$(find dist/ -name "*.whl" ! -name "*manylinux*.whl")
pip install "$UNREPAIRED_WHEEL_FILE"

# Change back to the original working directory (e.g., /app)
cd "$OLDPWD"

echo "--- Docker build complete! Library should be usable within the container. ---"