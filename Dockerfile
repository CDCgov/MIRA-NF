####################################################################################################
#BUILD SINGULARITY
####################################################################################################
FROM debian:bookworm-slim AS singularity-builder

ENV GO_VERSION=1.26.1
ENV SINGULARITY_VERSION=4.4.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libfuse-dev \
    libseccomp-dev \
    squashfs-tools \
    uidmap \
    zlib1g-dev \
    libsubid-dev \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add custom CA properly
COPY .certs/min-cdc-bundle-ca.crt /usr/local/share/ca-certificates/min-cdc-bundle-ca.crt

RUN cat /usr/local/share/ca-certificates/min-cdc-bundle-ca.crt >> /etc/ssl/certs/ca.crt && update-ca-certificates

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

####################################################################################################
# BUILD MIRA-NF IMAGE
####################################################################################################
FROM debian:bookworm-slim AS builder

# Copy singularity from builder stage
COPY --from=singularity-builder /usr/local/bin/singularity /usr/local/bin/
COPY --from=singularity-builder /usr/local/libexec/singularity /usr/local/libexec/singularity
COPY --from=singularity-builder /usr/local/etc/singularity /usr/local/etc/singularity
COPY --from=singularity-builder /usr/local/var/singularity /usr/local/var/singularity

# Install CA packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    vim \
    tar \
    curl \
    procps \
    openjdk-17-jre \
    dos2unix \
    fuse3 \
    runc \
    squashfs-tools \
    uidmap \
    && rm -rf /var/lib/apt/lists/*

# Add custom CA properly
COPY .certs/min-cdc-bundle-ca.crt /usr/local/share/ca-certificates/

RUN cat /usr/local/share/ca-certificates/min-cdc-bundle-ca.crt >> /etc/ssl/certs/ca.crt \
    && update-ca-certificates

# Project directory
ENV PROJECT_DIR=/MIRA-NF

# Copy project files
COPY . ${PROJECT_DIR}

RUN tar -xzf ${PROJECT_DIR}/sandboxes.tar.gz -C ${PROJECT_DIR} \
 && chmod -R 777 ${PROJECT_DIR}/sandboxes \
 && rm ${PROJECT_DIR}/sandboxes.tar.gz

############# Install nextflow packages ##################

# Create nextflow directories
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH="$JAVA_HOME/bin:$PATH"
ENV HOME=/root

# Pull Nextflow
RUN mkdir -p /root/.nextflow/framework/25.10.4 \
 && curl -L https://get.nextflow.io -o /usr/local/bin/nextflow --cacert /etc/ssl/certs/ca.crt \
 && chmod +x /usr/local/bin/nextflow \
 && curl -L https://www.nextflow.io/releases/v25.10.4/nextflow-25.10.4-one.jar \
      -o /root/.nextflow/framework/25.10.4/nextflow-25.10.4-one.jar \
      --cacert /etc/ssl/certs/ca.crt \
 && nextflow -version

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