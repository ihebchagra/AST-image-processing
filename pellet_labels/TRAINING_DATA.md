# Providing Custom Training Data for Pellet Label Detection

This document explains how to prepare and use your own training data for the pellet label detection model.

## 1. Data Format

The training pipeline expects your data to be organized in a specific directory structure, which is then compressed into a `.zip` file. Each `.zip` file should contain a single top-level directory, which in turn contains `train/` and `valid/` subdirectories. Inside `train/` and `valid/`, you should have subdirectories named after your classes, with image files inside them.

**Expected Directory Structure (before zipping):**

```
your_dataset_name/
├── train/
│   ├── class_A/
│   │   ├── image_001.jpg
│   │   ├── image_002.png
│   │   └── ...
│   ├── class_B/
│   │   ├── image_001.jpg
│   │   └── ...
│   └── ... (other training classes)
└── valid/
    ├── class_A/
    │   ├── image_xyz.jpg
    │   └── ...
    ├── class_B/
    │   ├── image_abc.png
    │   └── ...
    └── ... (other validation classes)
```

**Image Requirements:**

*   Images should be standard formats (e.g., JPG, PNG) readable by OpenCV (`cv2.imread`).
*   The training pipeline will automatically resize images to 64x64 pixels and convert them to grayscale.

## 2. Preparing Your Custom Data

1.  **Organize your images:** Create the directory structure as described above. Ensure your class names are consistent between `train/` and `valid/` if they represent the same classes.

2.  **Create a `.zip` file:** Compress the top-level directory (`your_dataset_name/`) into a single `.zip` file. For example, if your top-level directory is `my_custom_data/`, then create `my_custom_data.zip`.

3.  **Place the `.zip` file:** Copy your newly created `.zip` file into the `pellet_labels/data/` directory within your project.

    Example: `cp /path/to/your/my_custom_data.zip /home/iheb/Code/probe/AST-image-processing/pellet_labels/data/`

## 3. Integrating Your Data into the Training Process

To use your custom data, you need to modify the `pellet_labels/train_ensemble.sh` script.

### For Local Training

Locate the line that runs the local test of the trainer. It typically looks like this:

```bash
python3 -m trainer.task --job-dir ./models --train-files ./data/test_data.zip \
--num-epochs 1
```

Change the `--train-files` argument to point to your new `.zip` file:

```bash
python3 -m trainer.task --job-dir ./models --train-files ./data/my_custom_data.zip \
--num-epochs 1
```

### For Cloud Training (Google Cloud AI Platform)

If you plan to train on Google Cloud AI Platform, you must first upload your `.zip` file to a Google Cloud Storage (GCS) bucket.

Example GCS path: `gs://your-bucket-name/my_custom_data.zip`

Then, modify the `--train-files` argument in the `gcloud ai-platform jobs submit training` command within `train_ensemble.sh` to use your GCS path:

```bash
--train-files gs://pellet_labels/amman_atb_data.zip gs://pellet_labels/i2a_atb_data.zip \
--num-epochs=120 \
--weights 1 3
```

**Modified line (example):**

```bash
--train-files gs://your-bucket-name/my_custom_data.zip \
--num-epochs=120 \
--weights 1 3
```

## 4. Running the Training

After preparing your data and modifying `train_ensemble.sh`, you can run the training by executing the script:

```bash
./pellet_labels/train_ensemble.sh
```

## Important Note: Rebuilding the Project

**You DO NOT need to rebuild the entire `astimp` project (the C++ library and Python wheel) when you change your training data.** The training process is separate from the library compilation. You only need to prepare your data and run the `train_ensemble.sh` script.
