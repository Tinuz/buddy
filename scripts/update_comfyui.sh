#!/bin/bash
set -e

echo "=== Updating ComfyUI ==="

COMFYUI_DIR="${COMFYUI_DIR:-/workspace/ComfyUI}"

if [ ! -d "$COMFYUI_DIR" ]; then
    echo "❌ Error: ComfyUI directory not found at $COMFYUI_DIR"
    exit 1
fi

cd "$COMFYUI_DIR"

# Check if it's a git repository
if [ ! -d .git ]; then
    echo "❌ Error: $COMFYUI_DIR is not a git repository"
    echo "ComfyUI must be installed via git clone to enable updates"
    exit 1
fi

# Update ComfyUI core
echo "📥 Updating ComfyUI core..."
git fetch origin
git pull origin master || git pull origin main

echo "✓ ComfyUI core updated"
echo ""

# Update ComfyUI frontend
echo "📥 Updating ComfyUI frontend..."
if [ -d "web" ]; then
    cd web
    if [ -d .git ]; then
        git fetch origin
        git pull origin main || git pull origin master
        echo "✓ ComfyUI frontend updated"
    else
        echo "⚠️  Frontend is not a git submodule, skipping..."
    fi
    cd ..
else
    echo "⚠️  Frontend directory not found, skipping..."
fi

echo ""

# Update custom nodes
echo "📥 Updating custom nodes..."
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

if [ -d "$CUSTOM_NODES_DIR" ]; then
    cd "$CUSTOM_NODES_DIR"
    
    updated_count=0
    failed_count=0
    
    for node_dir in */; do
        if [ -d "$node_dir/.git" ]; then
            echo "  → Updating $(basename "$node_dir")..."
            cd "$node_dir"
            
            if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
                # Check if requirements.txt exists and install/update dependencies
                if [ -f "requirements.txt" ]; then
                    pip3 install --upgrade --upgrade-strategy only-if-needed -r requirements.txt > /dev/null 2>&1 || true
                fi
                updated_count=$((updated_count + 1))
            else
                echo "    ⚠️  Failed to update $(basename "$node_dir")"
                failed_count=$((failed_count + 1))
            fi
            
            cd ..
        fi
    done
    
    echo ""
    echo "✓ Updated $updated_count custom nodes"
    if [ $failed_count -gt 0 ]; then
        echo "⚠️  Failed to update $failed_count custom nodes"
    fi
else
    echo "⚠️  Custom nodes directory not found, skipping..."
fi

echo ""
echo "=================================="
echo "✅ ComfyUI Update Complete!"
echo "=================================="
echo ""
echo "Updated components:"
echo "  • ComfyUI core"
echo "  • ComfyUI frontend"
echo "  • Custom nodes ($updated_count updated)"
echo ""
echo "Restart ComfyUI to apply changes:"
echo "  cd $COMFYUI_DIR"
echo "  python main.py --listen 0.0.0.0 --port 8188"
echo ""
