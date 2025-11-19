#!/bin/bash
set -euo pipefail

# Runpod ComfyUI Setup Script
# Downloads project scripts and uses them to setup ComfyUI on Runpod
# Usage: 
#   ./setup_runpod.sh flux-dev              # Download FLUX.1-dev pack
#   ./setup_runpod.sh sdxl --with-nodes     # Download SDXL + install custom nodes
#   ./setup_runpod.sh wan22 --full          # Download WAN22 + install nodes + deps

echo "=================================="
echo "Runpod ComfyUI Setup Script"
echo "=================================="
echo ""

# Configuration
COMFYUI_DIR="${COMFYUI_DIR:-/workspace/runpod-slim/ComfyUI}"
MODEL_DIR="${MODEL_DIR:-/workspace/models}"
SCRIPT_DIR="/tmp/buddy-scripts"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/Tinuz/buddy/main/scripts"
INSTALL_NODES=false
INSTALL_DEPS=false
MODEL_PACK=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-nodes)
            INSTALL_NODES=true
            shift
            ;;
        --with-deps)
            INSTALL_DEPS=true
            shift
            ;;
        --full)
            INSTALL_NODES=true
            INSTALL_DEPS=true
            shift
            ;;
        --models-only)
            INSTALL_NODES=false
            INSTALL_DEPS=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [MODEL_PACK] [OPTIONS]"
            echo ""
            echo "Model Packs:"
            echo "  flux-dev        FLUX.1-dev (12B params, 34GB)"
            echo "  flux-schnell    FLUX.1-schnell (fast, 29GB)"
            echo "  sdxl            Stable Diffusion XL (13.5GB)"
            echo "  sdxl-biglove    SDXL Big Love checkpoint (6.8GB)"
            echo "  wan22           WAN 2.2 14B video (38GB)"
            echo "  qwen-image      Qwen Image Edit 2509 (14.7GB)"
            echo "  sd15            Stable Diffusion 1.5 (7.2GB)"
            echo "  upscalers       Upscaler pack (9.6GB)"
            echo ""
            echo "Options:"
            echo "  --with-nodes    Install custom ComfyUI nodes"
            echo "  --with-deps     Install Python dependencies"
            echo "  --full          Install nodes + deps (complete setup)"
            echo "  --models-only   Skip node and dependency installation (default)"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 flux-dev"
            echo "  $0 sdxl --with-nodes"
            echo "  $0 wan22 --full"
            exit 0
            ;;
        *)
            MODEL_PACK="$1"
            shift
            ;;
    esac
done

# Validate model pack
if [ -z "$MODEL_PACK" ]; then
    echo "❌ Error: No model pack specified"
    echo "Run '$0 --help' for usage information"
    exit 1
fi

# Check dependencies
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 not found"
    exit 1
fi

if ! command -v pip3 &> /dev/null; then
    echo "❌ Error: pip3 not found"
    exit 1
fi

if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo "❌ Error: wget or curl not found"
    exit 1
fi

echo "📋 Configuration:"
echo "   ComfyUI Directory: $COMFYUI_DIR"
echo "   Model Directory: $MODEL_DIR"
echo "   Model Pack: $MODEL_PACK"
echo "   Install Nodes: $INSTALL_NODES"
echo "   Install Deps: $INSTALL_DEPS"
echo ""

# Step 1: Download project scripts
echo "📥 Downloading project scripts from GitHub..."
mkdir -p "$SCRIPT_DIR"

SCRIPTS=(
    "download_models.py"
    "install_custom_nodes.sh"
    "install_python_deps.sh"
)

for script in "${SCRIPTS[@]}"; do
    echo "  → Downloading $script..."
    
    # Build download command with optional GitHub token for private repos
    if [ -n "$GITHUB_TOKEN" ]; then
        AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
    else
        AUTH_HEADER=""
    fi
    
    if command -v wget &> /dev/null; then
        if [ -n "$GITHUB_TOKEN" ]; then
            wget -q --header="$AUTH_HEADER" -O "$SCRIPT_DIR/$script" "$GITHUB_RAW_BASE/$script" || {
                echo "  ✗ Failed to download $script"
                echo "  Note: For private repos, set GITHUB_TOKEN environment variable"
                exit 1
            }
        else
            wget -q -O "$SCRIPT_DIR/$script" "$GITHUB_RAW_BASE/$script" || {
                echo "  ✗ Failed to download $script"
                echo "  Note: For private repos, set GITHUB_TOKEN environment variable"
                exit 1
            }
        fi
    else
        if [ -n "$GITHUB_TOKEN" ]; then
            curl -sSL -H "$AUTH_HEADER" -o "$SCRIPT_DIR/$script" "$GITHUB_RAW_BASE/$script" || {
                echo "  ✗ Failed to download $script"
                echo "  Note: For private repos, set GITHUB_TOKEN environment variable"
                exit 1
            }
        else
            curl -sSL -o "$SCRIPT_DIR/$script" "$GITHUB_RAW_BASE/$script" || {
                echo "  ✗ Failed to download $script"
                echo "  Note: For private repos, set GITHUB_TOKEN environment variable"
                exit 1
            }
        fi
    fi
    chmod +x "$SCRIPT_DIR/$script"
    echo "  ✓ Downloaded $script"
done

echo "✅ Scripts downloaded successfully"
echo ""

# Step 2: Install required Python packages for download_models.py
echo "📦 Installing required Python packages..."
pip3 install --quiet requests tqdm python-dotenv

# Step 3: Download models
echo "📥 Downloading model pack: $MODEL_PACK"
export MODEL_DIR="$MODEL_DIR"
python3 "$SCRIPT_DIR/download_models.py" "$MODEL_PACK"

if [ $? -ne 0 ]; then
    echo "❌ Model download failed"
    exit 1
fi

echo "✅ Models downloaded successfully"
echo ""

# Step 4: Install Python dependencies (optional)
if [ "$INSTALL_DEPS" = true ]; then
    echo "📦 Installing Python dependencies..."
    cd "$COMFYUI_DIR"
    export COMFYUI_DIR="$COMFYUI_DIR"
    bash "$SCRIPT_DIR/install_python_deps.sh"
    
    if [ $? -ne 0 ]; then
        echo "⚠️  Warning: Python dependency installation failed"
        echo "   Continuing with setup..."
    else
        echo "✅ Python dependencies installed"
    fi
    echo ""
fi

# Step 5: Install custom nodes (optional)
if [ "$INSTALL_NODES" = true ]; then
    echo "🔌 Installing custom ComfyUI nodes..."
    export COMFYUI_DIR="$COMFYUI_DIR"
    bash "$SCRIPT_DIR/install_custom_nodes.sh"
    
    if [ $? -ne 0 ]; then
        echo "⚠️  Warning: Custom node installation failed"
        echo "   Continuing with setup..."
    else
        echo "✅ Custom nodes installed"
    fi
    echo ""
fi

# Step 6: Cleanup
echo "🧹 Cleaning up..."
rm -rf "$SCRIPT_DIR"
echo "✅ Cleanup complete"
echo ""

# Final summary
echo "=================================="
echo "✅ Setup Complete!"
echo "=================================="
echo ""
echo "Model pack '$MODEL_PACK' has been installed to:"
echo "  $MODEL_DIR"
echo ""

if [ "$INSTALL_DEPS" = true ]; then
    echo "Python dependencies have been installed."
fi

if [ "$INSTALL_NODES" = true ]; then
    echo "Custom ComfyUI nodes have been installed to:"
    echo "  $COMFYUI_DIR/custom_nodes/"
    echo ""
    echo "Note: Some nodes may require additional setup or dependencies."
fi

echo ""
echo "To start ComfyUI, run:"
echo "  cd $COMFYUI_DIR"
echo "  python main.py --listen 0.0.0.0 --port 8188"
echo ""
