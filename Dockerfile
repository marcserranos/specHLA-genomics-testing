# Multi-stage build: Stage 1 builds indexes, Stage 2 is clean runtime

# ============ STAGE 1: Build (with index.sh) ============
FROM continuumio/miniconda3:latest as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget git curl build-essential cmake \
    perl pkg-config zlib1g-dev libbz2-dev \
    liblzma-dev libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /opt/spechla

# Clone SpecHLA from source
RUN git clone https://github.com/deepomicslab/SpecHLA.git --depth 1 .

# Fix bowtie2 index path bug (line 209: .fasta -> index prefix)
RUN sed -i 's|\-x \$db/ref/\$database_prefix\.fasta|\-x \$db/ref/\$database_prefix|g' script/whole/SpecHLA.sh

# Environment with BLAS for building indexes
COPY sandbox/SpecHLA/environment_docker.yml .

# Add BLAS libraries only for building (index.sh needs them)
RUN echo "  - arpack" >> environment_docker.yml && \
    echo "  - lapack" >> environment_docker.yml && \
    echo "  - blas" >> environment_docker.yml

# Configure conda and create environment
RUN conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda env create --prefix=/opt/spechla_env -f environment_docker.yml

# Make binaries executable
RUN chmod +x -R bin/

# Remove pre-compiled x86-64 binaries (use conda tools instead)
RUN rm -rf bin/* && mkdir -p bin

# Build bowtie2 indexes directly
RUN bash -c "export PATH=/opt/spechla_env/bin:\$PATH && \
             cd /opt/spechla/db/ref && \
             for fasta in *.fasta; do \
               prefix=\${fasta%.fasta}; \
               bowtie2-build \$fasta \$prefix 1>/dev/null 2>&1 || true; \
             done"

# Build SpecHap from source
RUN bash -c ". /opt/spechla_env/etc/profile.d/conda.sh && \
             conda activate /opt/spechla_env && \
             cd /opt/spechla/bin/SpecHap && \
             mkdir -p build && cd build && \
             cmake .. -DCMAKE_PREFIX_PATH=/opt/spechla_env && \
             make 2>&1" && \
             echo "SpecHap build complete" && \
             ls -la /opt/spechla/bin/SpecHap/build/SpecHap

# Build extractHairs from source
RUN bash -c ". /opt/spechla_env/etc/profile.d/conda.sh && \
             conda activate /opt/spechla_env && \
             cd /opt/spechla/bin/extractHairs && \
             mkdir -p build && cd build && \
             cmake .. -DCMAKE_PREFIX_PATH=/opt/spechla_env && \
             make 2>&1" && \
             echo "extractHairs build complete" && \
             ls -la /opt/spechla/bin/extractHairs/build/extractHAIRs

# ============ STAGE 2: Clean Runtime (no BLAS libraries) ============
FROM continuumio/miniconda3:latest

# Install only runtime system dependencies (no cmake/build-essential)
RUN apt-get update && apt-get install -y \
    wget git curl perl pkg-config \
    zlib1g-dev libbz2-dev liblzma-dev \
    libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /opt/spechla

# Clone SpecHLA (fresh, for scripts/db structure)
RUN git clone https://github.com/deepomicslab/SpecHLA.git --depth 1 .

# Fix bowtie2 index path bug
RUN sed -i 's|\-x \$db/ref/\$database_prefix\.fasta|\-x \$db/ref/\$database_prefix|g' script/whole/SpecHLA.sh

# Clean environment WITHOUT BLAS (avoids libblis errors at runtime)
COPY sandbox/SpecHLA/environment_docker.yml .

# Configure conda and create environment
RUN conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda env create --prefix=/opt/spechla_env -f environment_docker.yml

# Copy bowtie2 indexes and compiled tools from builder stage
COPY --from=builder /opt/spechla/db/ref/*.bt2* /opt/spechla/db/ref/
COPY --from=builder /opt/spechla/bin/SpecHap/build/SpecHap /opt/spechla/bin/
COPY --from=builder /opt/spechla/bin/extractHairs/build/extractHAIRs /opt/spechla/bin/

# Make binaries executable
RUN chmod +x /opt/spechla/bin/SpecHap /opt/spechla/bin/extractHAIRs

# Activate environment in shell
SHELL ["/bin/bash", "-c"]
RUN echo "source activate /opt/spechla_env" > ~/.bashrc

ENV PATH="/opt/spechla_env/bin:/opt/spechla/bin:$PATH"

# Set working directory for user data
WORKDIR /data

# Default command
ENTRYPOINT ["python3", "/opt/spechla/script/long_read_typing.py"]
