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

# --- Repair wheel with auditwheel to bundle shared libraries ---
echo "--- Repairing wheel with auditwheel ---"
UNREPAIRED_WHEEL_FILE=$(find dist/ -name "*.whl")
# Add current directory to LD_LIBRARY_PATH so auditwheel can find libastimp.so
export LD_LIBRARY_PATH=$(pwd):$LD_LIBRARY_PATH
# This will find libastimp.so, bundle it into the wheel, and fix RPATHs.
auditwheel repair "$UNREPAIRED_WHEEL_FILE" -w dist/

# Install the repaired manylinux wheel
echo "--- Installing the repaired wheel into the container's environment ---"
REPAIRED_WHEEL_FILE=$(find dist/ -name "*manylinux*.whl")
pip install "$REPAIRED_WHEEL_FILE"

# Change back to the original working directory (e.g., /app)
cd "$OLDPWD"

echo "--- Docker build complete! Library should be usable within the container. ---"