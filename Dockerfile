####################################################################################################
# BASE IMAGE
####################################################################################################
FROM debian:bookworm-slim AS builder

# Required certs for apk update
COPY .certs/min-cdc-bundle-ca.crt /etc/ssl/certs/ca.crt

# Put certs in /etc/ssl/certs location
RUN cat /etc/ssl/certs/ca.crt >> /etc/ssl/certs/curl-ca-bundle.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/curl-ca-bundle.crt

# Install system libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    vim \
    tar \
    curl \
    openjdk-17-jre \
    dos2unix \
    build-essential \
    golang \
    autoconf \
    automake \
    cryptsetup \
    git \
    fuse3 \
    libfuse-dev \
    libseccomp-dev \
    libtool \
    pkg-config \
    runc \
    squashfs-tools \
    uidmap \
    wget \
    zlib1g-dev \
    libsubid-dev \
    && rm -rf /var/lib/apt/lists/*

# Update CA trust store
RUN apt-get update && apt-get install -y ca-certificates-java && update-ca-certificates -f

# Project directory
ENV PROJECT_DIR=/mira-nf

# Copy project files
COPY . ${PROJECT_DIR}

############# Install nextflow packages ##################

# Create nextflow directories
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH="$JAVA_HOME/bin:$PATH"
ENV HOME=/root
RUN mkdir -p /root/.nextflow
RUN mkdir -p /root/.nextflow/framework/25.10.4

# Pull Nextflow
RUN curl -L https://get.nextflow.io -o /usr/local/bin/nextflow --cacert /etc/ssl/certs/ca.crt \
    && chmod +x /usr/local/bin/nextflow

# Get Java helper
RUN curl -L https://www.nextflow.io/releases/v25.10.4/nextflow-25.10.4-one.jar \
    -o /root/.nextflow/framework/25.10.4/nextflow-25.10.4-one.jar \
    --cacert /etc/ssl/certs/ca.crt

RUN nextflow -version

# Copy script
COPY MIRA_nextflow.sh ${PROJECT_DIR}/MIRA_nextflow.sh

# Convert Windows line endings
RUN dos2unix ${PROJECT_DIR}/MIRA_nextflow.sh

# Allow execution
RUN chmod +x ${PROJECT_DIR}/MIRA_nextflow.sh

############# Install GO ##################
# This has to be the most up to date version or it will fail
ENV GO_VERSION=1.26.1

RUN curl -L https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o go${GO_VERSION}.linux-amd64.tar.gz --cacert /etc/ssl/certs/ca.crt && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH=/usr/local/go/bin:$PATH

############# Install singularity ##################

# Install Apptainer
ENV SINGULARITY_VERSION=4.4.0

RUN curl -L https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz -o singularity-ce-${SINGULARITY_VERSION}.tar.gz --cacert /etc/ssl/certs/ca.crt && \
    tar -xzf singularity-ce-${SINGULARITY_VERSION}.tar.gz && \
    cd singularity-ce-${SINGULARITY_VERSION} && \
    ./mconfig && \
    make -C builddir && \
    make -C builddir install

############# Remove unused packages ##################

RUN rm -rf ${PROJECT_DIR}/fastqc \
    && rm -rf ${PROJECT_DIR}/multiqc

############# Set up working directory ##################

ENV WORKDIR=/data

# Create directory explicitly (fixes VOLUME error)
RUN mkdir -p ${WORKDIR}

# Docker volume
VOLUME ["/data"]

# Set working directory
WORKDIR /data

# Export project directory to PATH
ENV PATH="${PATH}:${PROJECT_DIR}"