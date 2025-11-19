#!/usr/bin/env python3
"""
Download model packs for ComfyUI workflows.

Each model pack includes the main model plus all required dependencies:
- CLIP encoders (text encoders)
- VAE (image decoder/encoder)
- LoRAs (optional enhancements)
- ControlNets (optional)
- IP-Adapters (optional)

Usage:
    python scripts/download_models.py flux-dev              # Download FLUX.1-dev pack
    python scripts/download_models.py sdxl                  # Download SDXL pack
    python scripts/download_models.py list                  # List all available packs
    python scripts/download_models.py flux-dev --skip-loras # Skip LoRA downloads
"""

import argparse
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional
from urllib.parse import urlparse
import hashlib

try:
    import requests
    from tqdm import tqdm
except ImportError:
    print("Error: Required packages not installed. Install with:")
    print("  pip install requests tqdm")
    sys.exit(1)

from dotenv import load_dotenv

load_dotenv()
MODEL_DIR = Path(os.getenv('MODEL_DIR', '/workspace/models'))

# ComfyUI directory structure
CHECKPOINTS_DIR = MODEL_DIR / 'checkpoints'
UNET_DIR = MODEL_DIR / 'unet'  # For diffusion transformers (DiT models)
UPSCALE_MODELS_DIR = MODEL_DIR / 'upscale_models'  # For upscaler models
VAE_DIR = MODEL_DIR / 'vae'
CLIP_DIR = MODEL_DIR / 'clip'
LORAS_DIR = MODEL_DIR / 'loras'
CONTROLNET_DIR = MODEL_DIR / 'controlnet'
IPADAPTER_DIR = MODEL_DIR / 'ipadapter'
EMBEDDINGS_DIR = MODEL_DIR / 'embeddings'
STYLE_MODELS_DIR = MODEL_DIR / 'style_models'  # For style models and embeddings

# Create all directories
for directory in [CHECKPOINTS_DIR, UNET_DIR, UPSCALE_MODELS_DIR, VAE_DIR, CLIP_DIR, LORAS_DIR, CONTROLNET_DIR, IPADAPTER_DIR, EMBEDDINGS_DIR, STYLE_MODELS_DIR]:
    directory.mkdir(parents=True, exist_ok=True)


# Model pack definitions
MODEL_PACKS = {
    'flux-dev': {
        'name': 'FLUX.1-dev',
        'description': 'Black Forest Labs FLUX.1-dev (12B parameter model)',
        'files': {
            'checkpoint': {
                'url': 'https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors',
                'path': CHECKPOINTS_DIR / 'flux1-dev.safetensors',
                'size': '23.8 GB'
            },
            'clip_l': {
                'url': 'https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors',
                'path': CLIP_DIR / 'clip_l.safetensors',
                'size': '246 MB'
            },
            't5xxl': {
                'url': 'https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors',
                'path': CLIP_DIR / 't5xxl_fp16.safetensors',
                'size': '9.79 GB'
            },
            'vae': {
                'url': 'https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors',
                'path': VAE_DIR / 'flux_vae.safetensors',
                'size': '335 MB'
            }
        },
        'loras': {
            'flux-realism': {
                'url': 'https://huggingface.co/XLabs-AI/flux-RealismLora/resolve/main/lora.safetensors',
                'path': LORAS_DIR / 'flux-realism.safetensors',
                'size': '382 MB',
                'optional': True
            }
        }
    },
    
    'flux-schnell': {
        'name': 'FLUX.1-schnell',
        'description': 'Black Forest Labs FLUX.1-schnell (fast inference)',
        'files': {
            'checkpoint': {
                'url': 'https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors',
                'path': CHECKPOINTS_DIR / 'flux1-schnell.safetensors',
                'size': '23.8 GB'
            },
            'clip_l': {
                'url': 'https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors',
                'path': CLIP_DIR / 'clip_l.safetensors',
                'size': '246 MB'
            },
            't5xxl': {
                'url': 'https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors',
                'path': CLIP_DIR / 't5xxl_fp8_e4m3fn.safetensors',
                'size': '4.89 GB'
            },
            'vae': {
                'url': 'https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors',
                'path': VAE_DIR / 'flux_vae.safetensors',
                'size': '335 MB'
            }
        }
    },
    
    'sdxl': {
        'name': 'Stable Diffusion XL',
        'description': 'Stability AI SDXL 1.0 base model',
        'files': {
            'checkpoint': {
                'url': 'https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors',
                'path': CHECKPOINTS_DIR / 'sd_xl_base_1.0.safetensors',
                'size': '6.94 GB'
            },
            'refiner': {
                'url': 'https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors',
                'path': CHECKPOINTS_DIR / 'sd_xl_refiner_1.0.safetensors',
                'size': '6.08 GB',
                'optional': True
            },
            'vae': {
                'url': 'https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors',
                'path': VAE_DIR / 'sdxl_vae.safetensors',
                'size': '335 MB'
            }
        },
        'loras': {
            'realistic_skin_texture': {
                'url': 'https://civitai.com/api/download/models/707763?token=b52f18fe1b10f6878747dbd8419924dc',
                'path': LORAS_DIR / 'realistic_skin_texture_v4.safetensors',
                'size': '144 MB',
                'optional': True
            },
            'skin_realism_acne': {
                'url': 'https://civitai.com/api/download/models/340833?token=b52f18fe1b10f6878747dbd8419924dc',
                'path': LORAS_DIR / 'skin_realism_acne_details.safetensors',
                'size': '143 MB',
                'optional': True
            },
            'touch_of_realism': {
                'url': 'https://civitai.com/api/download/models/1934796?token=b52f18fe1b10f6878747dbd8419924dc',
                'path': LORAS_DIR / 'touch_of_realism_sdxl_v2.safetensors',
                'size': '143 MB',
                'optional': True
            }
        },
        'embeddings': {
            'realistic_skin_ti': {
                'url': 'https://civitai.com/api/download/models/2192131?token=b52f18fe1b10f6878747dbd8419924dc',
                'path': EMBEDDINGS_DIR / 'RealisticSkin.safetensors',
                'size': '12 KB',
                'optional': True
            }
        }
    },
    
    'sdxl-biglove': {
        'name': 'SDXL Big Love (Photorealistic Checkpoint)',
        'description': 'Community fine-tuned SDXL checkpoint focused on photorealistic portraits',
        'files': {
            'checkpoint': {
                'url': 'https://civitai.com/api/download/models/2291289?token=b52f18fe1b10f6878747dbd8419924dc',
                'path': CHECKPOINTS_DIR / 'bigLove_insta1.safetensors',
                'size': '6.46 GB'
            },
            'vae': {
                'url': 'https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors',
                'path': VAE_DIR / 'sdxl_vae.safetensors',
                'size': '335 MB'
            }
        },
        'loras': {
            'realistic_skin_texture': {
                'url': 'https://civitai.com/api/download/models/707763?token=b52f18fe1b10f6878747dbd8419924dc',
                'path': LORAS_DIR / 'realistic_skin_texture_v4.safetensors',
                'size': '144 MB',
                'optional': True
            }
        }
    },
    
    'wan22': {
        'name': 'WAN 2.2 (Text-to-Video 14B)',
        'description': 'Wuerstchen Architecture Network 2.2 - High quality text-to-video generation (14B params)',
        'files': {
            'unet_low_noise': {
                'url': 'https://huggingface.co/MaxedOut/ComfyUI-Starter-Packs/resolve/main/Wan2.2/unet_14b/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors',
                'path': UNET_DIR / 'wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors',
                'size': '13.5 GB'
            },
            'unet_high_noise': {
                'url': 'https://huggingface.co/MaxedOut/ComfyUI-Starter-Packs/resolve/main/Wan2.2/unet_14b/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors',
                'path': UNET_DIR / 'wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors',
                'size': '13.5 GB'
            },
            'clip': {
                'url': 'https://huggingface.co/MaxedOut/ComfyUI-Starter-Packs/resolve/main/Wan2.2/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors',
                'path': CLIP_DIR / 'umt5_xxl_fp8_e4m3fn_scaled.safetensors',
                'size': '4.89 GB'
            },
            'vae': {
                'url': 'https://huggingface.co/MaxedOut/ComfyUI-Starter-Packs/resolve/main/Wan2.2/vae/wan_2.1_vae.safetensors',
                'path': VAE_DIR / 'wan_2.1_vae.safetensors',
                'size': '335 MB'
            }
        },
        'loras': {
            'lightning_low': {
                'url': 'https://huggingface.co/MaxedOut/ComfyUI-Starter-Packs/resolve/main/Wan2.2/loras_14b/Wan2.2-Lightning_T2V-v1.1-A14B-4steps-lora_LOW_fp16.safetensors',
                'path': LORAS_DIR / 'wan22_lightning_low_4steps.safetensors',
                'size': '2.1 GB',
                'optional': True
            },
            'lightning_high': {
                'url': 'https://huggingface.co/MaxedOut/ComfyUI-Starter-Packs/resolve/main/Wan2.2/loras_14b/Wan2.2-Lightning_T2V-v1.1-A14B-4steps-lora_HIGH_fp16.safetensors',
                'path': LORAS_DIR / 'wan22_lightning_high_4steps.safetensors',
                'size': '2.1 GB',
                'optional': True
            },
            'lenovo_ultrareal': {
                'url': 'https://civitai.com/api/download/models/2066914?token=b52f18fe1b10f6878747dbd8419924dc',
                'path': LORAS_DIR / 'lenovo_ultrareal_wan22.safetensors',
                'size': '2.1 GB',
                'optional': True
            }
        }
    },
    
    'qwen-image': {
        'name': 'Qwen Image Edit 2509 (Lightning)',
        'description': 'Alibaba Qwen 2.5 VL - Image editing and generation with 4-step Lightning inference',
        'files': {
            'checkpoint': {
                'url': 'https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_2509_fp8_scaled.safetensors',
                'path': CHECKPOINTS_DIR / 'qwen_image_2509_fp8_scaled.safetensors',
                'size': '7.8 GB'
            },
            'text_encoder': {
                'url': 'https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors',
                'path': CLIP_DIR / 'qwen_2.5_vl_7b_fp8_scaled.safetensors',
                'size': '4.2 GB'
            },
            'vae': {
                'url': 'https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors',
                'path': VAE_DIR / 'qwen_image_vae.safetensors',
                'size': '335 MB'
            }
        },
        'loras': {
            'lightning_v1': {
                'url': 'https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Lightning-4steps-V1.0.safetensors',
                'path': LORAS_DIR / 'qwen_image_lightning_4steps_v1.0.safetensors',
                'size': '1.2 GB',
                'optional': True
            },
            'lightning_alt': {
                'url': 'https://huggingface.co/alexgenovese/checkpoint/resolve/main/Qwen/Qwen-Image-Lightning-4steps-V1.0.safetensors',
                'path': LORAS_DIR / 'qwen_image_lightning_4steps_alt.safetensors',
                'size': '1.2 GB',
                'optional': True
            }
        }
    },
    
    'sd15': {
        'name': 'Stable Diffusion 1.5',
        'description': 'Classic SD 1.5 - still widely used',
        'files': {
            'checkpoint': {
                'url': 'https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors',
                'path': CHECKPOINTS_DIR / 'v1-5-pruned-emaonly.safetensors',
                'size': '3.97 GB'
            },
            'vae': {
                'url': 'https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors',
                'path': VAE_DIR / 'sd15_vae.safetensors',
                'size': '335 MB'
            }
        },
        'controlnet': {
            'canny': {
                'url': 'https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth',
                'path': CONTROLNET_DIR / 'control_v11p_sd15_canny.pth',
                'size': '1.45 GB',
                'optional': True
            },
            'depth': {
                'url': 'https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth',
                'path': CONTROLNET_DIR / 'control_v11f1p_sd15_depth.pth',
                'size': '1.45 GB',
                'optional': True
            }
        }
    },
    
    'upscalers': {
        'name': 'AI Upscaler Pack (Image & Video)',
        'description': 'Complete upscaling suite - ESRGAN, RealESRGAN, SeedVR2, and detail enhancement models',
        'files': {
            # Video upscaler - SeedVR2 (state-of-the-art)
            'seedvr2': {
                'url': 'https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/seedvr2_ema_7b_sharp_fp8_e4m3fn.safetensors',
                'path': UPSCALE_MODELS_DIR / 'seedvr2_ema_7b_sharp_fp8.safetensors',
                'size': '7.2 GB'
            },
            # Best general purpose image upscaler
            'realesrgan_x4plus': {
                'url': 'https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth',
                'path': UPSCALE_MODELS_DIR / 'RealESRGAN_x4plus.pth',
                'size': '64 MB'
            },
            # Anime-specific upscaler
            'realesrgan_x4plus_anime': {
                'url': 'https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth',
                'path': UPSCALE_MODELS_DIR / 'RealESRGAN_x4plus_anime_6B.pth',
                'size': '17.9 MB'
            },
            # Ultimate SD Upscale compatible - best quality
            'ultrasharp_4x': {
                'url': 'https://huggingface.co/lokCX/4x-Ultrasharp/resolve/main/4x-UltraSharp.pth',
                'path': UPSCALE_MODELS_DIR / '4x-UltraSharp.pth',
                'size': '67 MB'
            },
            # Detail enhancement - faces and textures
            'lollypop_4x': {
                'url': 'https://huggingface.co/Kim2091/UltraSharp/resolve/main/4x-Lollypop.pth',
                'path': UPSCALE_MODELS_DIR / '4x-Lollypop.pth',
                'size': '67 MB',
                'optional': True
            },
            # NMKD Superscale - photorealistic
            'nmkd_superscale': {
                'url': 'https://huggingface.co/gemasai/4x_NMKD-Superscale-SP_178000_G/resolve/main/4x_NMKD-Superscale-SP_178000_G.pth',
                'path': UPSCALE_MODELS_DIR / '4x_NMKD-Superscale-SP_178000_G.pth',
                'size': '67 MB',
                'optional': True
            },
            # LDSR upscaler (latent diffusion)
            'ldsr': {
                'url': 'https://huggingface.co/lllyasviel/Annotators/resolve/main/ldsr/last.ckpt',
                'path': UPSCALE_MODELS_DIR / 'ldsr.ckpt',
                'size': '2.0 GB',
                'optional': True
            }
        },
        'loras': {
            # Detail enhancement LoRA
            'skin_detail_lite': {
                'url': 'https://huggingface.co/gemasai/x1_ITF_SkinDiffDetail_Lite_v1/resolve/main/x1_ITF_SkinDiffDetail_Lite_v1.safetensors',
                'path': LORAS_DIR / 'skin_detail_lite_v1.safetensors',
                'size': '144 MB',
                'optional': True
            },
            # Clarity and sharpness enhancement
            'detail_tweaker': {
                'url': 'https://huggingface.co/Birchlabs/detail-tweaker-xl/resolve/main/detail-tweaker-xl.safetensors',
                'path': LORAS_DIR / 'detail_tweaker_xl.safetensors',
                'size': '23 MB',
                'optional': True
            }
        }
    }
}


def download_file(url: str, destination: Path, description: str = None) -> bool:
    """Download a file with progress bar."""
    if destination.exists():
        print(f"  ✓ {destination.name} already exists, skipping")
        return True
    
    print(f"  → Downloading {description or destination.name}...")
    print(f"    URL: {url}")
    
    try:
        response = requests.get(url, stream=True, timeout=30)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        with open(destination, 'wb') as f, tqdm(
            total=total_size,
            unit='B',
            unit_scale=True,
            unit_divisor=1024,
            desc=f"    {destination.name}"
        ) as pbar:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    pbar.update(len(chunk))
        
        print(f"  ✓ Downloaded to {destination}")
        return True
        
    except Exception as e:
        print(f"  ✗ Error downloading {destination.name}: {e}")
        if destination.exists():
            destination.unlink()
        return False


def download_model_pack(pack_name: str, skip_optional: bool = False, skip_loras: bool = False, skip_controlnet: bool = False) -> bool:
    """Download a complete model pack with all dependencies."""
    if pack_name not in MODEL_PACKS:
        print(f"Error: Model pack '{pack_name}' not found")
        print(f"Available packs: {', '.join(MODEL_PACKS.keys())}")
        return False
    
    pack = MODEL_PACKS[pack_name]
    print(f"\n{'='*60}")
    print(f"Downloading: {pack['name']}")
    print(f"Description: {pack['description']}")
    print(f"{'='*60}\n")
    
    success = True
    
    # Download main files
    print("📦 Main model files:")
    for file_name, file_info in pack['files'].items():
        if skip_optional and file_info.get('optional', False):
            print(f"  ⊘ Skipping optional file: {file_name}")
            continue
        
        size = file_info.get('size', 'unknown size')
        if not download_file(file_info['url'], file_info['path'], f"{file_name} ({size})"):
            if not file_info.get('optional', False):
                success = False
    
    # Download LoRAs
    if 'loras' in pack and not skip_loras:
        print("\n🎨 LoRA files:")
        for lora_name, lora_info in pack['loras'].items():
            if skip_optional and lora_info.get('optional', False):
                print(f"  ⊘ Skipping optional LoRA: {lora_name}")
                continue
            
            size = lora_info.get('size', 'unknown size')
            download_file(lora_info['url'], lora_info['path'], f"{lora_name} ({size})")
    
    # Download ControlNets
    if 'controlnet' in pack and not skip_controlnet:
        print("\n🎮 ControlNet files:")
        for cn_name, cn_info in pack['controlnet'].items():
            if skip_optional and cn_info.get('optional', False):
                print(f"  ⊘ Skipping optional ControlNet: {cn_name}")
                continue
            
            size = cn_info.get('size', 'unknown size')
            download_file(cn_info['url'], cn_info['path'], f"{cn_name} ({size})")
    
    print(f"\n{'='*60}")
    if success:
        print(f"✅ Model pack '{pack['name']}' downloaded successfully!")
    else:
        print(f"⚠️  Model pack '{pack['name']}' downloaded with some errors")
    print(f"{'='*60}\n")
    
    return success


def list_model_packs():
    """List all available model packs."""
    print("\n📋 Available Model Packs:\n")
    print(f"{'='*80}")
    
    for pack_name, pack in MODEL_PACKS.items():
        print(f"\n🔹 {pack_name}")
        print(f"   Name: {pack['name']}")
        print(f"   Description: {pack['description']}")
        
        # Count files
        main_files = len(pack['files'])
        loras = len(pack.get('loras', {}))
        controlnets = len(pack.get('controlnet', {}))
        
        print(f"   Includes: {main_files} main files", end="")
        if loras > 0:
            print(f", {loras} LoRAs", end="")
        if controlnets > 0:
            print(f", {controlnets} ControlNets", end="")
        print()
        
        # Calculate total size
        total_size = sum(
            float(f.get('size', '0 GB').split()[0]) 
            for f in pack['files'].values() 
            if 'GB' in f.get('size', '')
        )
        print(f"   Estimated size: ~{total_size:.1f} GB")
    
    print(f"\n{'='*80}\n")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Download ComfyUI model packs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/download_models.py list                    # List all packs
  python scripts/download_models.py flux-dev                # Download FLUX.1-dev
  python scripts/download_models.py sdxl --skip-loras       # Download SDXL without LoRAs
  python scripts/download_models.py sd15 --skip-optional    # Skip optional files
        """
    )
    
    parser.add_argument(
        'pack',
        choices=list(MODEL_PACKS.keys()) + ['list'],
        help='Model pack to download (or "list" to show all packs)'
    )
    parser.add_argument(
        '--skip-optional',
        action='store_true',
        help='Skip optional files (like refiners)'
    )
    parser.add_argument(
        '--skip-loras',
        action='store_true',
        help='Skip LoRA downloads'
    )
    parser.add_argument(
        '--skip-controlnet',
        action='store_true',
        help='Skip ControlNet downloads'
    )
    
    args = parser.parse_args()
    
    if args.pack == 'list':
        list_model_packs()
    else:
        success = download_model_pack(
            args.pack,
            skip_optional=args.skip_optional,
            skip_loras=args.skip_loras,
            skip_controlnet=args.skip_controlnet
        )
        sys.exit(0 if success else 1)
