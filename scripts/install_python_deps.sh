#!/bin/bash
set -e

echo "=== Installing Python Dependencies ==="

# Install additional dependencies for custom nodes
# Note: onnxruntime-gpu is only available on x86_64, will be skipped on ARM64
pip3 install --no-cache-dir \
    onnxruntime \
    opencv-python \
    scikit-image \
    numba \
    colour-science \
    kornia \
    gguf \
    simpleeval \
    mediapipe \
    ultralytics \
    segment_anything

# Try to install GPU version of onnxruntime
pip3 install --no-cache-dir onnxruntime-gpu || echo "onnxruntime-gpu not available on this platform, using CPU version"

# Install insightface separately with all its dependencies
pip3 install --no-cache-dir \
    numpy \
    onnx \
    tqdm \
    requests \
    matplotlib \
    Pillow \
    scipy \
    scikit-learn \
    easydict \
    cython \
    albumentations \
    prettytable

pip3 install --no-cache-dir insightface

echo "✓ Python dependencies installation complete"
