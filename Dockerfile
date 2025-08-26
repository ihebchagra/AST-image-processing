# Use a manylinux image for maximum compatibility
# This image comes with Python, pip, and patchelf pre-installed,
# and is designed for building portable Linux wheels.
FROM quay.io/pypa/manylinux_2_28_x86_64

# Install additional build dependencies
# cmake and git are needed for your project's build process
RUN yum install -y cmake git opencv-devel gtest-devel pkgconfig

# Set PKG_CONFIG_PATH for OpenCV
ENV PKG_CONFIG_PATH="/usr/lib64/pkgconfig:$PKG_CONFIG_PATH"

# Set the working directory inside the container
WORKDIR /app

# Copy your entire project into the container
# This assumes you run 'docker build' from your project's root directory
# --- Source Code for AST-image-processing Library ---
# Choose ONE of the following options:

# Option 1: Clone from GitHub (for self-contained image, recommended for deployment)
# This will fetch the library source code directly from GitHub.
RUN git clone https://github.com/ihebchagra/AST-image-processing.git /tmp/astimp-src

# Option 2: Copy from build context (if you're building the library from local source)
# This assumes the AST-image-processing library source is in the build context.
# COPY . /tmp/astimp-src

# --- End Source Code Selection ---

# Create and activate a Python virtual environment
# This ensures project dependencies are isolated
RUN /opt/python/cp39-cp39/bin/python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies, including auditwheel
# auditwheel is crucial for making the wheel portable
RUN pip install auditwheel wheel
RUN pip install -r /tmp/astimp-src/python-module/requirements.txt

# Execute the custom build script
# This script will handle building the C++ library,
# the Python wheel, and repairing it with auditwheel.
RUN bash docker_build.sh /tmp/astimp-src

# Set the default command to run when the container starts
# This will drop you into a bash shell where you can inspect the build
CMD ["bash"]
