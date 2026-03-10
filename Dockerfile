####################################################################################################
# BASE IMAGE
####################################################################################################
FROM debian:bookworm-slim AS builder

# Install CA packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    vim \
    tar \
    curl \
    openjdk-17-jre \
    dos2unix \
    build-essential \
    coreutils \
    autoconf \
    automake \
    fuse3 \
    libfuse-dev \
    libseccomp-dev \
    libtool \
    pkg-config \
    runc \
    squashfs-tools \
    uidmap \
    zlib1g-dev \
    libsubid-dev \
    && rm -rf /var/lib/apt/lists/*

# Add custom CA properly
COPY .certs/min-cdc-bundle-ca.crt /usr/local/share/ca-certificates/min-cdc-bundle-ca.crt

# For curl to work
RUN cat /usr/local/share/ca-certificates/min-cdc-bundle-ca.crt >> /etc/ssl/certs/ca.crt

# Update system + Java truststores
RUN update-ca-certificates

# Project directory
ENV PROJECT_DIR=/MIRA-NF

# Copy project files
COPY . ${PROJECT_DIR}

##TODO: get these sandboxes in better place
# Copy script
COPY sandboxes.tar.gz ${PROJECT_DIR}/sandboxes.tar.gz

RUN tar -xzf ${PROJECT_DIR}/sandboxes.tar.gz

# Allow execution
RUN chmod -R 777 ${PROJECT_DIR}/sandboxes

RUN rm ${PROJECT_DIR}/sandboxes.tar.gz

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
ENV SINGULARITY_VERSION=4.4.0

RUN curl -L https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz -o singularity-ce-${SINGULARITY_VERSION}.tar.gz --cacert /etc/ssl/certs/ca.crt && \
    tar -xzf singularity-ce-${SINGULARITY_VERSION}.tar.gz && \
    cd singularity-ce-${SINGULARITY_VERSION} && \
    ./mconfig && \
    make -C builddir && \
    make -C builddir install

RUN rm singularity-ce-${SINGULARITY_VERSION}

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