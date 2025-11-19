# WAN 2.2 Text-to-Image Workflow

Een eenvoudige workflow voor het genereren van images met WAN 2.2 14B model.

## Benodigdheden

- **Model Pack**: `wan22` (geïnstalleerd via `setup_runpod.sh wan22`)
- **Models**:
  - `wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors` (UNet)
  - `umt5_xxl_fp8_e4m3fn_scaled.safetensors` (CLIP)
  - `wan_2.1_vae.safetensors` (VAE)

## Workflow Nodes

### 1. CheckpointLoaderSimple
- Laadt het WAN 2.2 14B model
- **Model**: `wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors`

### 2. CLIPTextEncode (Positive)
- Positieve prompt voor wat je wilt genereren
- **Voorbeeld**: "A beautiful landscape with mountains and a lake at sunset, highly detailed, cinematic lighting, 8k quality"

### 3. CLIPTextEncode (Negative)
- Negatieve prompt voor wat je NIET wilt
- **Voorbeeld**: "blurry, low quality, distorted, watermark, text, bad anatomy, worst quality"

### 4. EmptyLatentImage
- Definieert de image grootte
- **Default**: 1024x1024 pixels
- **Batch Size**: 1

### 5. KSampler
- Sampling instellingen:
  - **Steps**: 20 (kan verhoogd worden voor betere kwaliteit)
  - **CFG Scale**: 7.0 (hogere waarde = meer prompt adherence)
  - **Sampler**: euler_ancestral
  - **Scheduler**: normal
  - **Denoise**: 1.0

### 6. VAEDecode
- Decodeert latent space naar image

### 7. SaveImage
- Slaat de gegenereerde image op
- **Prefix**: ComfyUI_WAN22

## Gebruik

1. Open ComfyUI in je browser
2. Klik op "Load" en selecteer `wan22_text_to_image.json`
3. Pas de positive prompt aan naar wat je wilt genereren
4. Optioneel: pas negative prompt, steps, CFG scale aan
5. Klik op "Queue Prompt"
6. Wacht tot de image gegenereerd is

## Tips

- **Betere kwaliteit**: Verhoog steps naar 30-50
- **Meer prompt adherence**: Verhoog CFG scale naar 8-10
- **Verschillende variaties**: Klik op "randomize" bij seed
- **Sneller**: Verlaag steps naar 15
- **Grotere images**: Pas width/height aan (let op VRAM gebruik)

## VRAM Gebruik

- **1024x1024**: ~12-14 GB VRAM
- **1536x1536**: ~18-20 GB VRAM
- **2048x2048**: ~24-28 GB VRAM

Voor RTX 4090 (24GB) is 1024x1024 tot 1536x1536 veilig.

## Troubleshooting

**Out of memory error?**
- Verlaag image size naar 768x768 of 512x512
- Sluit andere applicaties
- Gebruik de fp8 versie van het model (al standaard)

**Slechte image kwaliteit?**
- Verhoog steps naar 30+
- Verbeter je prompt met meer details
- Voeg meer negatieve prompts toe

**Model laadt niet?**
- Controleer of de models gedownload zijn: `ls /workspace/models/unet/`
- Run setup script opnieuw: `./setup_runpod.sh wan22`
