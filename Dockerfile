FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

ENV PATH=/opt/conda/bin:$PATH

# Set working directory
WORKDIR /workspace

# Copy environment file and code
COPY environment.yaml .
COPY semantic_uncertainty/ ./semantic_uncertainty/

# Accept conda Terms of Service
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Create conda environment
RUN conda env create -f environment.yaml && \
    conda clean -afy

# Initialize conda for bash
RUN conda init bash

# Fix PyTorch installation to avoid iJIT_NotifyEvent symbol issue
# Uninstall conda PyTorch and reinstall via pip with explicit CUDA support
RUN /opt/conda/envs/semantic_uncertainty/bin/pip uninstall -y torch torchvision torchaudio && \
    /opt/conda/envs/semantic_uncertainty/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Set default shell to bash with conda activated
SHELL ["/bin/bash", "-c"]

# Default command activates environment and starts bash
CMD ["/bin/bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate semantic_uncertainty && /bin/bash"]

