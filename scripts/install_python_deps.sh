#!/bin/bash
set -e

echo "=== Installing Python Dependencies ==="

# Check if main packages are already installed
check_installed() {
    python3 -c "import $1" 2>/dev/null && return 0 || return 1
}

# Quick check for key packages
if check_installed "insightface" && check_installed "ultralytics" && check_installed "segment_anything"; then
    echo "✓ Main dependencies already installed, checking for updates..."
    INSTALL_MODE="--upgrade --upgrade-strategy only-if-needed"
else
    echo "Installing dependencies for the first time..."
    INSTALL_MODE=""
fi

# Install additional dependencies for custom nodes
# Note: onnxruntime-gpu is only available on x86_64, will be skipped on ARM64
echo "Installing core dependencies..."
pip3 install $INSTALL_MODE \
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
echo "Checking for GPU runtime..."
pip3 install $INSTALL_MODE onnxruntime-gpu || echo "⚠️  onnxruntime-gpu not available on this platform, using CPU version"

# Install insightface separately with all its dependencies
echo "Installing insightface dependencies..."
pip3 install $INSTALL_MODE \
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
    prettytable \
    insightface

echo ""
echo "✓ Python dependencies installation complete"
echo ""
echo "Note: PyTorch and SageAttention are installed separately by setup_runpod.sh"
