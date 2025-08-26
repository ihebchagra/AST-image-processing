# Generating the Python Library Output

This document explains how to generate the `astimp` Python library (`.whl` file) from the project source code.

## Prerequisites

Before you begin, ensure you have the following system dependencies installed:

*   **C++ Compiler and Build Tools:** `build-essential` (for Debian/Ubuntu) or `gcc` (for Void Linux) or equivalent.
*   **CMake:** A cross-platform build system.
*   **OpenCV Development Libraries:** `libopencv-dev` (for Debian/Ubuntu) or `opencv` (for Void Linux) or equivalent.
*   **Python 3 Development Headers:** `python3-dev` (for Debian/Ubuntu) or `python3-devel` (for Void Linux) or equivalent.
*   **Python 3 `pip` and `venv`:** For managing Python packages and virtual environments.

**Example installation command for Void Linux:**

```bash
sudo xbps-install -S build-essential cmake opencv python3-devel python3-pip python3-venv
```

## Steps to Generate the Python Library

1.  **Navigate to the project root directory:**

    ```bash
    cd /home/iheb/Code/probe/AST-image-processing
    ```

2.  **Run the build script:**

    Execute the `build.sh` script. This script will automate the entire process of compiling the C++ library and building the Python wheel.

    ```bash
    ./build.sh
    ```

    **What `build.sh` does:**

    *   Creates a Python virtual environment (`venv/`) in the project root.
    *   Installs necessary Python build dependencies (including `setuptools`) into the virtual environment.
    *   Compiles the core C++ library (`libastimp.so`) using CMake.
    *   Builds the `astimp` Python wheel (`.whl` file) using `setup.py`.

3.  **Locate the generated wheel file:**

    Once the `build.sh` script completes successfully, the `astimp` Python wheel file (`.whl`) will be located in the `python-module/dist/` directory.

    Example: `python-module/dist/astimp-1.1.4-cp313-cp313-linux_x86_64.whl`

## Using the Generated Library

You can now use this `.whl` file to install the `astimp` library into any compatible Python environment using `pip`:

```bash
pip install path/to/your/astimp-X.Y.Z-py3-none-any.whl
```

**Important Note on Shared Libraries:**

The `astimp` Python library depends on the `libastimp.so` shared C++ library. When using the installed Python package, you must ensure that `libastimp.so` is discoverable by your system's dynamic linker. The `build.sh` script places `libastimp.so` in `build/astimplib/`. You can make it discoverable by:

*   **Setting `LD_LIBRARY_PATH`:** Temporarily set the `LD_LIBRARY_PATH` environment variable to include the directory containing `libastimp.so` before running your Python application:

    ```bash
    export LD_LIBRARY_PATH=/home/iheb/Code/probe/AST-image-processing/build/astimplib:$LD_LIBRARY_PATH
    python your_script.py
    ```

*   **Installing to a system-wide location:** (Advanced) Copy `libastimp.so` to a standard system library path (e.g., `/usr/local/lib`) and run `ldconfig`. This requires root privileges.

*   **Using a self-contained distribution:** For easier portability, consider creating a self-contained distribution that bundles the `.whl` file and `libastimp.so` together, along with a setup script that configures `LD_LIBRARY_PATH` automatically. (This was covered in a previous step if you chose to create it).
