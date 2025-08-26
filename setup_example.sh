#!/bin/bash

# Exit on any error
set -e

# Define paths
MAIN_PROJECT_DIR="$(dirname "$0")"
EXAMPLE_PROJECT_DIR="${MAIN_PROJECT_DIR}/astimp-example"
ASTIMP_WHEEL_PATH="${MAIN_PROJECT_DIR}/python-module/dist/astimp-1.1.4-cp313-cp313-linux_x86_64.whl"
ASTIMP_LIB_DIR="${MAIN_PROJECT_DIR}/build/astimplib"
EXAMPLE_IMAGE_SRC="${MAIN_PROJECT_DIR}/tests/images/IMG_20180107_184023.jpg"

# Create example project directory
echo "--- Creating example project directory: ${EXAMPLE_PROJECT_DIR} ---"
mkdir -p "${EXAMPLE_PROJECT_DIR}"

# Create and activate virtual environment
echo "--- Creating virtual environment in ${EXAMPLE_PROJECT_DIR}/venv ---"
python3 -m venv "${EXAMPLE_PROJECT_DIR}/venv"
source "${EXAMPLE_PROJECT_DIR}/venv/bin/activate"

# Install astimp wheel
echo "--- Installing astimp wheel into virtual environment ---"
pip install --no-cache-dir --force-reinstall "${ASTIMP_WHEEL_PATH}"

# Copy example image
echo "--- Copying example image ---"
cp "${EXAMPLE_IMAGE_SRC}" "${EXAMPLE_PROJECT_DIR}/"

# Create example.py script
echo "--- Creating example.py script ---"
cat <<EOF > "${EXAMPLE_PROJECT_DIR}/example.py"
import astimp
import imageio.v2 as imageio
import os

# Set LD_LIBRARY_PATH for the current process
os.environ['LD_LIBRARY_PATH'] = "${ASTIMP_LIB_DIR}:" + os.environ.get('LD_LIBRARY_PATH', '')

# Load the image
im = imageio.imread("IMG_20180107_184023.jpg")

# Find antibiotic pellets
circles = astimp.find_atb_pellets(im)

# Print the results
print(f"Found {len(circles)} pellets:")
for i, circle in enumerate(circles):
    print(f"  Pellet {i+1}: center=(\"{circle.center[0]:.2f}\", \"{circle.center[1]:.2f}\"), radius=\"{circle.radius:.2f}\")
EOF

# Provide instructions
echo "\n--- Example project setup complete! ---"
echo "To run the example:"
echo "1. Navigate to the example directory: cd ${EXAMPLE_PROJECT_DIR}"
echo "2. Activate the virtual environment: source venv/bin/activate"
echo "3. Run the example script: python example.py"
echo "\nNote: The LD_LIBRARY_PATH is set automatically within the example.py script."
