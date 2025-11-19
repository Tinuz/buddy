#!/bin/bash
set -e

echo "=== Installing Custom Nodes ==="

COMFYUI_DIR="${COMFYUI_DIR:-/workspace/ComfyUI}"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

# Create custom_nodes directory if it doesn't exist
mkdir -p "$CUSTOM_NODES_DIR"
cd "$CUSTOM_NODES_DIR"

# Helper function to install a node if it doesn't exist
install_node() {
    local repo_url="$1"
    local node_name=$(basename "$repo_url" .git)
    local install_deps="${2:-false}"
    local extra_setup="${3:-}"
    
    if [ -d "$node_name" ]; then
        echo "✓ $node_name already installed, skipping..."
        return 0
    fi
    
    echo "Installing $node_name..."
    if git clone "$repo_url" 2>/dev/null; then
        if [ "$install_deps" = "true" ] && [ -f "$node_name/requirements.txt" ]; then
            cd "$node_name"
            pip3 install --no-cache-dir -r requirements.txt || true
            cd ..
        fi
        
        if [ -n "$extra_setup" ]; then
            cd "$node_name"
            eval "$extra_setup" || true
            cd ..
        fi
        
        echo "✓ $node_name installed"
    else
        echo "⚠️  Failed to install $node_name"
    fi
}

# Core Management
install_node "https://github.com/ltdrdata/ComfyUI-Manager.git"
install_node "https://github.com/Fannovel16/comfyui_controlnet_aux.git" "true"
install_node "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "true" "git submodule update --init --recursive"
install_node "https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git" "true"
install_node "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
install_node "https://github.com/WASasquatch/was-node-suite-comfyui.git" "true"
install_node "https://github.com/cubiq/ComfyUI_essentials.git" "true"
install_node "https://github.com/rgthree/rgthree-comfy.git"
install_node "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git"
install_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" "true"
install_node "https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git"
install_node "https://github.com/jags111/efficiency-nodes-comfyui.git"
install_node "https://github.com/BlenderNeko/ComfyUI_Cutoff.git"
install_node "https://github.com/BlenderNeko/ComfyUI_Noise.git"
install_node "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
install_node "https://github.com/Gourieff/comfyui-reactor-node.git" "true"
install_node "https://github.com/receyuki/comfyui-prompt-reader-node.git" "true" "git submodule update --init --recursive"
install_node "https://github.com/city96/ComfyUI-GGUF.git" "true"
install_node "https://github.com/cubiq/ComfyUI_InstantID.git" "true"
install_node "https://github.com/kijai/ComfyUI-Florence2.git" "true"
install_node "https://github.com/chengzeyi/ParaAttention.git" "true" "if [ ! -f __init__.py ]; then echo '# ParaAttention nodes' > __init__.py; fi"

echo ""
echo "✓ Custom nodes installation complete"
