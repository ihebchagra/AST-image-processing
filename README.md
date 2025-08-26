# AST-Image-Processing Project Guide

This README provides a comprehensive guide on setting up the development environment using Docker, building the project, and extending the pellet label recognition model.

## Table of Contents
1.  [Project Overview](#1-project-overview)
2.  [Setting Up the Development Environment with Docker](#2-setting-up-the-development-environment-with-docker)
3.  [Developing a Web Server using ASTimp](#3-developing-a-web-server-using-astimp)
4.  [Training the Pellet Label Recognition Model](#4-training-the-pellet-label-recognition-model)
5.  [Adding New Pellet Classes to the Model](#5-adding-new-pellet-classes-to-the-model)

---

## 1. Project Overview
This project focuses on image processing for antibiotic susceptibility testing (AST), specifically for pellet label recognition. It involves a C++ library for core image processing functionalities and a Python module for higher-level tasks, including machine learning model training and integration.

## 2. Setting Up the Development Environment with Docker

This section explains how to set up a portable development environment for the `AST-image-processing` library itself. This environment will build the C++ library and Python module without worrying about system-specific dependencies.

### Prerequisites

*   **Docker:** Ensure Docker is installed and running on your system.
    *   If you encounter `permission denied` errors when running Docker commands, you might need to add your user to the `docker` group: `sudo usermod -aG docker $USER` and then re-login. Alternatively, you can prepend `sudo` to Docker commands.

### Dockerfile and Build Script

Ensure the `Dockerfile` and `docker_build.sh` script are present in the root directory of your `AST-image-processing` project. These files were previously created by the AI agent.

### Building the `astimp-builder` Docker Image

Navigate to the root directory of your `AST-image-processing` project (where your `Dockerfile` and `docker_build.sh` are located) in your terminal.

Run the following command to build the Docker image:

```bash
docker build -t astimp-builder .
```

*   `-t astimp-builder`: Tags the image with the name `astimp-builder` for easy reference.
*   `.`: Specifies the build context (the current directory), meaning Docker will send your `Dockerfile` and `docker_build.sh` to the Docker daemon.

This process will:
*   Download the `manylinux_2_28_x86_64` base image.
*   **Clone the `AST-image-processing` library from GitHub (or copy it if you chose that option in the Dockerfile).**
*   Install necessary build tools (cmake, git, opencv-devel, gtest-devel, pkgconfig).
*   Set up a Python 3.9 virtual environment.
*   Install Python dependencies (from the *cloned library's* `requirements.txt`, including `auditwheel` and `wheel`).
*   Execute the `docker_build.sh` script inside the container, which will:
    *   Build the C++ library (`libastimp.so`).
    *   Build the Python wheel (`.whl`).
    *   Manually set the RPATH on the generated Python extension.
    *   Install the built Python wheel into the container's virtual environment.

The build process might take some time, especially on the first run.

## 3. Developing a Web Server using ASTimp

This section outlines the recommended architecture for developing a web server that utilizes the `astimp` library. This setup ensures hot-reloading for your web server code, local Git management, and a clean separation of environments.

### Architecture Overview

*   **`astimp-builder` Image:** This image (built in Section 2) contains the pre-compiled `astimp` library.
*   **Your Web Server Project:** This is a new, separate Python project on your host machine, managed by its own Git repository. It will contain your web server code and its specific Python dependencies.
*   **Development Container:** A Docker container based on `astimp-builder` will mount your local web server project, allowing for hot-reloading during development.

### Your Web Server Project Setup (on your host machine)

Create a new directory for your web server project and initialize it:

```bash
mkdir my_web_server_project
cd my_web_server_project
git init
# Create your web server files (e.g., app.py, requirements.txt)
```

**`my_web_server_project/requirements.txt` (Example):**

```
flask
gunicorn
# Any other dependencies your web server needs, EXCEPT astimp (it's in the base image)
```

**`my_web_server_project/Dockerfile.dev`:**

```dockerfile
# Use the image that already has astimp built and installed
FROM astimp-builder

# Set the working directory for your web server project inside the container
WORKDIR /app

# Install web server specific Python dependencies
# We copy requirements.txt first to leverage Docker caching
COPY requirements.txt .
RUN pip install -r requirements.txt

# Expose the port your web server will listen on
EXPOSE 8000 # Example port

# Default command to run your web server in development mode
CMD ["bash"]
```

**`my_web_server_project/.dockerignore` (Crucial for hot reloading):**

```
venv/
__pycache__/
.git/
*.pyc
*.log
.vscode/
.idea/
# Add any other files/folders that should NOT be copied into the image
# or mounted unnecessarily.
```


### Building and Running Your Web Server Development Container

1.  **Navigate to your web server project directory:**
    ```bash
    cd /path/to/my_web_server_project/
    ```

2.  **Build your web server's development image:**
    ```bash
    docker build -f Dockerfile.dev -t my-web-server-dev .
    ```

3.  **Run the development container with volume mount and hot reloading:**
    This command will mount your local project into the container, allowing changes on your host to be immediately reflected.
    ```bash
docker run -it --rm -v "$(pwd)":/app -p <HOST_PORT>:8000 my-web-server-dev <SERVER_START_COMMAND>
    ```

*   `-it`: Interactive and pseudo-TTY.
*   `--rm`: Automatically remove the container when it exits.
*   `-v "$(pwd)":/app`: **Mounts your current local project directory (`$(pwd)`) to `/app` inside the container.** This is how hot reloading works.
*   `-p <HOST_PORT>:8000`: Maps a port from your host (e.g., `8000`) to the container's exposed port (`8000`).
*   `my-web-server-dev`: The name of the image you just built.
*   `<SERVER_START_COMMAND>`: Replace this with the actual command to start your web server in development mode with hot reloading.
    *   **Example (Flask):** `flask run --host=0.0.0.0 --port=8000 --debug`
    *   **Example (Gunicorn with Flask app `app.py`):** `gunicorn app:app -b 0.0.0.0:8000 --reload`


### Using the Development Environment

Inside the Docker container:

*   Your *new Python project* files will be at `/app`. Changes you make on your host machine will be immediately reflected here.
*   The `astimp` Python library (built from the cloned GitHub repository) will be installed in the Python virtual environment and ready for import.
*   The C++ libraries will be built and accessible.

You can verify the `astimp` library installation by running Python and trying to import `astimp` from *anywhere* in the container:

```bash
python
>>> import astimp
>>> # If no errors, the library is successfully loaded.
```

## 4. Training the Pellet Label Recognition Model

The training process is managed by scripts within the `pellet_labels/` directory of the *cloned AST-image-processing library*.

### Data Preparation

Your raw training data, typically images and their corresponding labels, are expected to be organized and placed within the `pellet_labels/data/` directory of the *cloned library*. You will need to copy your data into the container's `/tmp/astimp-src/pellet_labels/data/` directory.

### Training Execution

The primary script for initiating training is `pellet_labels/train_ensemble.sh` located in `/tmp/astimp-src/pellet_labels/`. This shell script sets up the necessary Python environment and then calls a Python program, likely `pellet_labels/trainer/task.py`. This Python script handles the core machine learning tasks:
*   Loading and preprocessing the data from the `data/` directory.
*   Defining and configuring the neural network model (often specified in `pellet_labels/trainer/model.py`).
*   Executing the training loops, including optimization and evaluation.
*   Saving the resulting trained model files (e.g., `.h5` and `.tflite` formats) into the `pellet_labels/models/` directory.

### Model Integration

Once the training is complete and a new `.tflite` model is generated (e.g., `ensemble_model.tflite`), this model is automatically picked up by the C++ build process. A custom command in `astimplib/CMakeLists.txt` uses a Python script (`pellet_labels/generate_cpp_model.py`) to convert this `.tflite` model into C++ code. This C++ code is then compiled into `libastimp.so`, embedding your newly trained model directly into the library.

## 5. Adding New Pellet Classes to the Model

Adding new classes of pellets is a more significant change than just adding more images to existing classes. It requires careful steps to ensure the model is correctly retrained and integrated.

### 1. Data Preparation for New Classes

Organize your new pellet images into the same structured format as your existing training data. Each new class should have its own subdirectory within the `train/` and `valid/` splits of your dataset.

**Example Directory Structure (with a new class 'class_C'):**

```
your_updated_dataset_name/
├── train/
│   ├── class_A/
│   ├── class_B/
│   ├── class_C/  # <--- New class data
│   │   ├── new_pellet_001.jpg
│   │   └── ...
│   └── ...
└── valid/
    ├── class_A/
    ├── class_B/
    ├── class_C/  # <--- New class data
│   │   ├── new_pellet_xyz.jpg
│   │   └── ...
    └── ...
```

Compress this entire updated dataset directory into a new `.zip` file (e.g., `my_updated_data.zip`).

Copy this new `.zip` file into the `pellet_labels/data/` directory within the *cloned library's source* (i.e., `/tmp/astimp-src/pellet_labels/data/` inside the container).

### 2. Update `pellet_labels/pellet_list.py`

This file is crucial as it defines the classes your model recognizes. You will **need to edit this file** (located at `/tmp/astimp-src/pellet_labels/pellet_list.py` inside the container) to add the names of your new pellet classes to the existing list. Ensure the class names you add here exactly match the directory names you used in your training data.

### 3. Verify Model Architecture Adaptation (`pellet_labels/trainer/model.py`)

Your classification model's final output layer must match the total number of classes. Ideally, your `trainer/model.py` is designed to automatically adapt its output layer size based on the number of unique class directories it finds in the training data. 

*   **Review `pellet_labels/trainer/model.py`:** Check if the model dynamically determines the output layer size (e.g., by reading the number of subdirectories in the training data).
*   **Manual Adjustment (if needed):** If the model's output layer size is hardcoded, you will need to manually modify `trainer/model.py` (located at `/tmp/astimp-src/pellet_labels/trainer/model.py` inside the container) to increase the size of the final output layer to `(current_number_of_classes + number_of_new_classes)`.

### 4. Retrain the Model

After preparing your data and updating the necessary Python files, you must retrain the model. This will create a new `.tflite` model that includes your new classes.

1.  **Modify `pellet_labels/train_ensemble.sh`:** Update the `--train-files` argument to point to your new `.zip` file containing all your data (old and new classes). This file is located at `/tmp/astimp-src/pellet_labels/train_ensemble.sh` inside the container.
2.  **Run the Training Script:** Execute the script from the *cloned library's root* inside the container:
    ```bash
    cd /tmp/astimp-src/pellet_labels
    ./train_ensemble.sh
    ```
    This process will generate new `.h5` and `.tflite` model files in `/tmp/astimp-src/pellet_labels/models/`.

### 5. Rebuild the C++ Library and Python Wheel

The C++ library (`libastimp.so`) embeds the `.tflite` model. To ensure your application uses the newly trained model with the added classes, you must rebuild the library and the Python wheel.

1.  **Rebuild the Docker Image:** You need to rebuild the Docker image to incorporate the newly trained model into the library. This will trigger the `docker_build.sh` script, which in turn rebuilds the C++ library with the new `.tflite` model and then the Python wheel.
    ```bash
    docker build -t astimp-builder .
    ```
2.  **Verify in Container:** Once the Docker build is complete, run the container and verify that the `astimp` module can be imported and potentially test its functionality with the new classes.

By following these steps, your model will be retrained to recognize the new pellet classes, and the updated model will be integrated into your C++ library and Python module.
