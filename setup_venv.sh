#!/bin/bash

# Exit on any error
set -e

# Define paths
MAIN_PROJECT_DIR="$(dirname "$0")"
ASTIMP_WHEEL_PATH="${MAIN_PROJECT_DIR}/python-module/dist/astimp-1.1.4-cp313-cp313-linux_x86_64.whl"
ASTIMP_LIB_DIR="${MAIN_PROJECT_DIR}/build/astimplib"

# Create virtual environment
echo "--- Creating virtual environment: ./venv ---"
python3 -m venv venv

# Activate virtual environment
echo "--- Activating virtual environment ---"
source venv/bin/activate

# Install astimp wheel
echo "--- Installing astimp wheel ---"
pip install --no-cache-dir --force-reinstall "${ASTIMP_WHEEL_PATH}"

# Modify activate script to set LD_LIBRARY_PATH
echo "--- Modifying venv/bin/activate to set LD_LIBRARY_PATH ---"
echo "export LD_LIBRARY_PATH=\"${ASTIMP_LIB_DIR}:\$LD_LIBRARY_PATH\"" >> venv/bin/activate

echo "--- Setup complete! ---"
echo "To activate the virtual environment and use astimp, run: source venv/bin/activate"
