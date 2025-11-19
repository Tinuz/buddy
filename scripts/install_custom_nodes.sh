#!/bin/bash
set -e

echo "=== Installing Custom Nodes ==="

cd /workspace/ComfyUI/custom_nodes

# Core Management
echo "Installing ComfyUI-Manager..."
git clone https://github.com/ltdrdata/ComfyUI-Manager.git

echo "Installing ControlNet Auxiliary Preprocessors..."
git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    cd comfyui_controlnet_aux && \
    pip3 install --no-cache-dir -r requirements.txt && \
    cd ..

echo "Installing ComfyUI Impact Pack..."
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && \
    git submodule update --init --recursive && \
    pip3 install --no-cache-dir -r requirements.txt && \
    cd ..

echo "Installing ComfyUI Inspire Pack..."
git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git && \
    cd ComfyUI-Inspire-Pack && \
    pip3 install --no-cache-dir -r requirements.txt && \
    cd ..

echo "Installing IPAdapter Plus..."
git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git

echo "Installing WAS Node Suite..."
git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    cd was-node-suite-comfyui && \
    pip3 install --no-cache-dir -r requirements.txt && \
    cd ..

echo "Installing ComfyUI Essentials..."
git clone https://github.com/cubiq/ComfyUI_essentials.git && \
    cd ComfyUI_essentials && \
    pip3 install --no-cache-dir -r requirements.txt && \
    cd ..

echo "Installing rgthree's ComfyUI Nodes..."
git clone https://github.com/rgthree/rgthree-comfy.git

echo "Installing ComfyUI-AnimateDiff-Evolved..."
git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git

echo "Installing ComfyUI-VideoHelperSuite..."
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    pip3 install --no-cache-dir -r requirements.txt && \
    cd ..

echo "Installing ComfyUI-Advanced-ControlNet..."
git clone https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git

echo "Installing Efficiency Nodes..."
git clone https://github.com/jags111/efficiency-nodes-comfyui.git

echo "Installing ComfyUI Cutoff..."
git clone https://github.com/BlenderNeko/ComfyUI_Cutoff.git

echo "Installing ComfyUI Noise..."
git clone https://github.com/BlenderNeko/ComfyUI_Noise.git

echo "Installing Ultimate SD Upscale..."
git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git

echo "Installing Reactor Node (face swap)..."
git clone https://github.com/Gourieff/comfyui-reactor-node.git && \
    cd comfyui-reactor-node && \
    pip3 install --no-cache-dir -r requirements.txt || true && \
    cd ..

echo "Installing ComfyUI Prompt Reader..."
git clone --recursive https://github.com/receyuki/comfyui-prompt-reader-node.git && \
    cd comfyui-prompt-reader-node && \
    git submodule update --init --recursive && \
    pip3 install --no-cache-dir -r requirements.txt || true && \
    cd ..

echo "Installing ComfyUI-GGUF..."
git clone https://github.com/city96/ComfyUI-GGUF.git && \
    cd ComfyUI-GGUF && \
    pip3 install --no-cache-dir -r requirements.txt || true && \
    cd ..

echo "Installing ComfyUI_InstantID..."
git clone https://github.com/cubiq/ComfyUI_InstantID.git && \
    cd ComfyUI_InstantID && \
    pip3 install --no-cache-dir -r requirements.txt || true && \
    cd ..

echo "Installing ComfyUI-Florence2..."
git clone https://github.com/kijai/ComfyUI-Florence2.git && \
    cd ComfyUI-Florence2 && \
    pip3 install --no-cache-dir -r requirements.txt || true && \
    cd ..

echo "Installing ParaAttention..."
git clone https://github.com/chengzeyi/ParaAttention.git && \
    cd ParaAttention && \
    if [ ! -f __init__.py ]; then echo '# ParaAttention nodes' > __init__.py; fi && \
    pip3 install --no-cache-dir -r requirements.txt || true && \
    cd ..

echo "✓ Custom nodes installation complete"
