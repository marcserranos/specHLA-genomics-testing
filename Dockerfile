FROM continuumio/miniconda3:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget git curl build-essential cmake \
    perl pkg-config zlib1g-dev libbz2-dev \
    liblzma-dev libcurl4-openssl-dev libssl-dev \
    libarpack2-dev liblapack-dev libblas-dev \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /opt/spechla

# Clone SpecHLA from source
RUN git clone https://github.com/deepomicslab/SpecHLA.git --depth 1 .

# Copy custom environment file
COPY sandbox/SpecHLA/environment_docker.yml .

# Configure conda and create environment
RUN conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda env create --prefix=/opt/spechla_env -f environment_docker.yml

# Make binaries executable (skip index.sh since bowtie2 indexes already exist)
RUN chmod +x -R bin/

# Activate environment in shell
SHELL ["/bin/bash", "-c"]
RUN echo "source activate /opt/spechla_env" > ~/.bashrc

ENV PATH="/opt/spechla_env/bin:/opt/spechla/bin:$PATH"

# Set working directory for user data
WORKDIR /data

# Default command
ENTRYPOINT ["python3", "/opt/spechla/script/long_read_typing.py"]
