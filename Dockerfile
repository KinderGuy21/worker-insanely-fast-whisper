# Base image
FROM pytorch/pytorch:2.0.1-cuda11.7-cudnn8-devel

ARG HUGGING_FACE_HUB_WRITE_TOKEN
ENV HUGGING_FACE_HUB_WRITE_TOKEN=$HUGGING_FACE_HUB_WRITE_TOKEN

ENV HF_HOME="/cache/huggingface"
ENV HF_DATASETS_CACHE="/cache/huggingface/datasets"
ENV DEFAULT_HF_METRICS_CACHE="/cache/huggingface/metrics"
ENV DEFAULT_HF_MODULES_CACHE="/cache/huggingface/modules"
ENV HUGGINFACE_HUB_CACHE="/cache/huggingface/hub"
ENV HUGGINGFACE_ASSETS_CACHE="/cache/huggingface/assets"

ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /workspace

RUN apt-get update && apt-get install -y ffmpeg git

# Install Python Dependencies
COPY builder/requirements.txt /requirements.txt

# 1. Upgrade pip
# 2. Install a known compatible flash-attn wheel from a prebuilt URL (replace URL with an actual working link)
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /requirements.txt && \
    pip install flash-attn --no-build-isolation && \
    rm /requirements.txt

# Cache Models
COPY builder/cache_model.py /cache_model.py
RUN python /cache_model.py && rm /cache_model.py

# Copy Source Code
ADD src .

RUN test -n "$(ls -A /cache/huggingface)"

CMD ["python", "-u", "handler.py"]
