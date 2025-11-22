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

# Smart model directory detection:
# If ComfyUI exists, download directly to its models folder
# Otherwise use /workspace/models
if [ -d "$COMFYUI_DIR/models" ]; then
    MODEL_DIR="${MODEL_DIR:-$COMFYUI_DIR/models}"
else
    MODEL_DIR="${MODEL_DIR:-/workspace/models}"
fi

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
    "update_comfyui.sh"
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

# Step 2: Setup PyTorch and SageAttention in ComfyUI venv
if [ -d "$COMFYUI_DIR" ]; then
    echo "🔥 Installing PyTorch CUDA 12.9 in ComfyUI venv..."
    
    # Activate ComfyUI venv
    VENV_PATH="$COMFYUI_DIR/venv"
    if [ -f "$VENV_PATH/bin/activate" ]; then
        source "$VENV_PATH/bin/activate"
        echo "  ✓ Activated venv at $VENV_PATH"
    else
        echo "  ⚠️  No venv found at $VENV_PATH, using system Python"
    fi
    
    # Uninstall old PyTorch
    echo "  → Removing old PyTorch installation..."
    pip uninstall -y torch torchvision torchaudio 2>/dev/null || true
    pip cache purge
    
    # Install PyTorch CUDA 12.9
    echo "  → Installing PyTorch with CUDA 12.9..."
    pip install torch torchvision torchaudio triton --index-url https://download.pytorch.org/whl/cu129
    
    echo "  ✓ PyTorch CUDA 12.9 installed"
    echo ""
    
    # Install SageAttention from source
    echo "🚀 Installing SageAttention from source..."
    
    # Check if already installed
    if python3 -c "import sageattention" 2>/dev/null; then
        echo "  ✓ SageAttention already installed"
    else
        # Install required build dependencies (all CUDA dev libraries)
        echo "  → Installing CUDA development libraries..."
        apt-get update -qq && apt-get install -y -qq \
            libcublas-dev-12-4 \
            libcusparse-dev-12-4 \
            libcusolver-dev-12-4 \
            libcurand-dev-12-4 \
            ninja-build \
            || echo "  ⚠️  Could not install some CUDA libraries, may already be present"
        
        SAGEATTENTION_DIR="/tmp/SageAttention"
        if [ -d "$SAGEATTENTION_DIR" ]; then
            rm -rf "$SAGEATTENTION_DIR"
        fi
        
        git clone https://github.com/thu-ml/SageAttention.git "$SAGEATTENTION_DIR" || {
            echo "  ⚠️  Failed to clone SageAttention, continuing..."
        }
        
        if [ -d "$SAGEATTENTION_DIR" ]; then
            cd "$SAGEATTENTION_DIR"
            
            # Set CUDA paths explicitly
            export CUDA_HOME=/usr/local/cuda
            export PATH=$CUDA_HOME/bin:$PATH
            export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
            export LIBRARY_PATH=$CUDA_HOME/lib64:$LIBRARY_PATH
            export CPATH=$CUDA_HOME/include:$CPATH
            export C_INCLUDE_PATH=$CUDA_HOME/include:$C_INCLUDE_PATH
            export CPLUS_INCLUDE_PATH=$CUDA_HOME/include:$CPLUS_INCLUDE_PATH
            
            # Set build optimization flags
            export MAX_JOBS=4
            export TORCH_CUDA_ARCH_LIST="8.9"  # RTX 4090/5090
            export FORCE_CUDA=1
            
            echo "  → Building SageAttention (this may take 5-10 minutes)..."
            echo "  → Using CUDA at: $CUDA_HOME"
            echo "  → Note: Ignoring CUDA version warnings (12.4 vs 12.9 is OK)"
            
            # Use pip install with verbose output for debugging
            pip install --verbose --no-cache-dir . 2>&1 | grep -v "^building\|^copying\|^creating" || {
                echo "  ⚠️  SageAttention installation failed"
                echo "  💡 This is optional - ComfyUI will work without it"
                cd - > /dev/null
            }
            
            cd - > /dev/null
            
            # Only remove if installation succeeded
            if python3 -c "import sageattention" 2>/dev/null; then
                rm -rf "$SAGEATTENTION_DIR"
                echo "  ✓ SageAttention installed successfully"
            else
                echo "  ⚠️  SageAttention installation incomplete, keeping source at $SAGEATTENTION_DIR for debugging"
            fi
        fi
    fi
    
    # Deactivate venv if we activated it
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
    fi
    
    echo "✅ PyTorch and SageAttention setup complete"
    echo ""
fi

# Step 3: Update ComfyUI to latest version
if [ -d "$COMFYUI_DIR" ]; then
    echo "🔄 Updating ComfyUI to latest version..."
    export COMFYUI_DIR="$COMFYUI_DIR"
    bash "$SCRIPT_DIR/update_comfyui.sh" || {
        echo "⚠️  Warning: ComfyUI update failed, continuing with setup..."
    }
    echo ""
fi

# Step 4: Install required Python packages for download_models.py
echo "📦 Installing required Python packages..."
pip3 install --quiet requests tqdm python-dotenv

# Step 5: Download models
echo "📥 Downloading model pack: $MODEL_PACK"
export MODEL_DIR="$MODEL_DIR"
python3 "$SCRIPT_DIR/download_models.py" "$MODEL_PACK"

if [ $? -ne 0 ]; then
    echo "❌ Model download failed"
    exit 1
fi

echo "✅ Models downloaded successfully"
echo ""

# Step 6: Download workflows for this model pack
WORKFLOWS_DIR="$COMFYUI_DIR/user/default/workflows"
mkdir -p "$WORKFLOWS_DIR"

echo "📥 Downloading workflows for $MODEL_PACK..."

# Map model packs to their workflows
case "$MODEL_PACK" in
    wan22)
        echo "  → Downloading WAN 2.2 text-to-image workflow..."
        if command -v wget &> /dev/null; then
            wget -q -O "$WORKFLOWS_DIR/wan22_text_to_image.json" "$GITHUB_RAW_BASE/../workflows/wan22_text_to_image.json" || echo "  ⚠️  Failed to download workflow"
        else
            curl -sSL -o "$WORKFLOWS_DIR/wan22_text_to_image.json" "$GITHUB_RAW_BASE/../workflows/wan22_text_to_image.json" || echo "  ⚠️  Failed to download workflow"
        fi
        ;;
    flux-dev|flux-schnell)
        echo "  → FLUX workflows coming soon..."
        ;;
    sdxl|sdxl-biglove)
        echo "  → SDXL workflows coming soon..."
        ;;
    qwen-image)
        echo "  → Qwen Image workflows coming soon..."
        ;;
    *)
        echo "  → No specific workflows for $MODEL_PACK"
        ;;
esac

echo "✅ Workflows ready"
echo ""

# Step 7: Merge models to ComfyUI directory (if needed)
echo "📦 Checking model directory setup..."
echo "  📂 Model directory: $MODEL_DIR"
echo "  📂 ComfyUI models: $COMFYUI_DIR/models"

# Only merge if MODEL_DIR is different from ComfyUI models directory
if [ "$MODEL_DIR" != "$COMFYUI_DIR/models" ]; then
    # Create ComfyUI models directory if it doesn't exist
    mkdir -p "$COMFYUI_DIR/models"
    
    if [ -d "$MODEL_DIR" ] && [ -n "$(ls -A "$MODEL_DIR" 2>/dev/null)" ]; then
        echo "  → Merging models from $MODEL_DIR to $COMFYUI_DIR/models..."
        
        # Check if rsync is available, fallback to cp
        if command -v rsync &> /dev/null; then
            rsync -av "$MODEL_DIR/" "$COMFYUI_DIR/models/" || {
                echo "  ⚠️  rsync failed, trying with cp..."
                cp -rv "$MODEL_DIR/"* "$COMFYUI_DIR/models/" 2>/dev/null || true
            }
            echo "  ✓ Models merged with rsync"
        else
            echo "  ⚠️  rsync not found, using cp..."
            cp -rv "$MODEL_DIR/"* "$COMFYUI_DIR/models/" || true
            echo "  ✓ Models copied with cp"
        fi
        
        echo "✅ Models merged to ComfyUI directory"
    else
        echo "  ℹ️  No models to merge (directory empty or doesn't exist)"
    fi
else
    echo "  ✓ Models already in ComfyUI directory, no merge needed"
fi
echo ""

# Step 8: Install Python dependencies (optional)
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

# Step 9: Install custom nodes (optional)
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

# Step 10: Cleanup
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
