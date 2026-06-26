# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN git clone https://github.com/scraed/LanPaint /comfyui/custom_nodes/LanPaint
RUN git clone https://github.com/chrisgoringe/cg-use-everywhere /comfyui/custom_nodes/cg-use-everywhere && cd /comfyui/custom_nodes/cg-use-everywhere && (git checkout f72d23a7060db657a2775c4dd1f1a85a3efcf5a8 2>/dev/null || (git fetch origin f72d23a7060db657a2775c4dd1f1a85a3efcf5a8 --depth=1 && git checkout f72d23a7060db657a2775c4dd1f1a85a3efcf5a8) || echo "WARN: commit f72d23a7060db657a2775c4dd1f1a85a3efcf5a8 unreachable in https://github.com/chrisgoringe/cg-use-everywhere, falling back to default branch HEAD")
RUN git clone https://github.com/rgthree/rgthree-comfy /comfyui/custom_nodes/rgthree-comfy
RUN git clone https://github.com/goodguy1963/ComfyUI-ThinkingLLM.git /comfyui/custom_nodes/comfyui-thinkingllm

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/sume180635/qwen3-4b-fp8-scaled/resolve/main/qwen3_4b_fp8_scaled.safetensors' --relative-path models/text_encoders --filename 'qwen3_4b_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors' --relative-path models/vae --filename 'flux2-vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/YuCollection/FLUX.2-klein-4B-bf16/resolve/main/flux-2-klein-4b.safetensors' --relative-path models/diffusion_models --filename 'flux-2-klein-4b-bf16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/gemma-4/resolve/main/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors' --relative-path models/text_encoders --filename 'gemma4_e4b_it_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-peterfazekas-1137340.jpg' "https://cool-anteater-319.convex.cloud/api/storage/df3f1b08-4a37-411c-af6f-94196c9dad29"
RUN wget --progress=dot:giga -O '/comfyui/input/indian_ethnic_wear_male1.webp' "https://cool-anteater-319.convex.cloud/api/storage/e2569b9d-7f24-4b2c-a776-95c9cc65227f"
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-alina-zahorulko-48514961-31445409.jpg' "https://cool-anteater-319.convex.cloud/api/storage/867f8cd5-2bb4-4885-8682-d35c852266fd"
RUN wget --progress=dot:giga -O '/comfyui/input/Indian_male_model_1.png' "https://cool-anteater-319.convex.cloud/api/storage/318e2752-8dfd-4af7-b349-340e5912dcec"
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-mimfathi-10919291.jpg' "https://cool-anteater-319.convex.cloud/api/storage/af0e0e80-ccd5-43e0-81d8-cfc07bd8819e"

# =====================================================================
# ADDED FOR LOG VERBOSITY AND DYNAMIC ENTRYPOINT ROUTING
# =====================================================================

# 1. Force Python to dump console output instantly instead of caching/buffering it
ENV PYTHONUNBUFFERED=1

# 2. Start ComfyUI and dynamically locate and execute your handler file
CMD ["bash", "-c", "python3 /comfyui/main.py --listen 127.0.0.1 --port 8188 & python3 $(find / -maxdepth 2 -name '*handler.py' | head -n 1)"]
