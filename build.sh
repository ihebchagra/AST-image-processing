#!/bin/bash

# Exit on any error
set -e

# --- Create and activate Python virtual environment ---
echo "--- Creating Python virtual environment ---"
python3 -m venv venv
source venv/bin/activate

# --- Install Python dependencies ---
echo "--- Installing Python dependencies ---"
pip install --upgrade pip
pip install setuptools
pip install -r python-module/requirements.txt

# --- Build the C++ library ---
echo "--- Building C++ library ---"
if [ ! -d "build" ]; then
    mkdir build
fi
cd build
cmake ..
make
cd ..

# --- Build the Python wheel ---
echo "--- Building Python wheel ---"
cd python-module
python setup.py bdist_wheel
cd ..

echo "--- Build complete! ---"
echo "The wheel file can be found in python-module/dist/"
