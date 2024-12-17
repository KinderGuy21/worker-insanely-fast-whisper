# Base image
FROM runpod/pytorch:1.13.0-py3.10-cuda11.7.1-devel

ARG HUGGING_FACE_HUB_WRITE_TOKEN
ENV HUGGING_FACE_HUB_WRITE_TOKEN=$HUGGING_FACE_HUB_WRITE_TOKEN

ENV HF_HOME="/cache/huggingface"
ENV HF_DATASETS_CACHE="/cache/huggingface/datasets"
ENV DEFAULT_HF_METRICS_CACHE="/cache/huggingface/metrics"
ENV DEFAULT_HF_MODULES_CACHE="/cache/huggingface/modules"
ENV HUGGINFACE_HUB_CACHE="/cache/huggingface/hub"
ENV HUGGINGFACE_ASSETS_CACHE="/cache/huggingface/assets"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /workspace

RUN apt-get update && apt-get install -y ffmpeg

# Install Python Dependencies
COPY builder/requirements.txt /requirements.txt

# 1. Upgrade pip
# 2. Install a known compatible flash-attn wheel from a prebuilt URL (replace URL with an actual working link)
RUN pip install --upgrade pip && \
    pip install --no-cache-dir https://flash-attention-releases.s3.amazonaws.com/wheels/cu117/torch1.13.0/flash_attn-2.0.9%2Bcu117-cp310-cp310-linux_x86_64.whl && \
    pip install --no-cache-dir -r /requirements.txt && \
    rm /requirements.txt

# Cache Models
COPY builder/cache_model.py /cache_model.py
RUN python /cache_model.py && rm /cache_model.py

# Copy Source Code
ADD src .

RUN test -n "$(ls -A /cache/huggingface)"

CMD ["python", "-u", "handler.py"]
