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

############# Install Singularity with GO ##################
# This has to be the most up to date version or it will fail
ENV GO_VERSION=1.26.1
ENV SINGULARITY_VERSION=4.4.0

RUN curl -L https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o go.tgz \
 && tar -C /usr/local -xzf go.tgz \
 && rm go.tgz \
 && PATH=/usr/local/go/bin:$PATH \
 && curl -L https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz -o s.tgz \
 && tar -xzf s.tgz \
 && cd singularity-ce-${SINGULARITY_VERSION} \
 && ./mconfig \
 && make -C builddir \
 && make -C builddir install \
 && rm -rf /usr/local/go s.tgz singularity-ce-${SINGULARITY_VERSION}

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
    python3.11 \
    python3-pip \
    python3-setuptools \
    && rm -rf /var/lib/apt/lists/*

# Add custom CA properly
COPY .certs/min-cdc-bundle-ca.crt /usr/local/share/ca-certificates/

RUN cat /usr/local/share/ca-certificates/min-cdc-bundle-ca.crt >> /etc/ssl/certs/ca.crt \
    && update-ca-certificates

# Create environment variable to get base python version
ARG python_version
ENV python_version=${python_version:-python3.10}

# Update pip and setuptools and then install python packages
RUN pip install --no-cache-dir --upgrade pip --break-system-packages

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

############# Set up MIRA-NF ##################

# Project directory
ENV PROJECT_DIR=/MIRA-NF

# Copy project files
COPY . ${PROJECT_DIR}

RUN tar -xzf ${PROJECT_DIR}/sandboxes.tar.gz -C ${PROJECT_DIR} \
 && chmod -R 777 ${PROJECT_DIR}/sandboxes \
 && rm ${PROJECT_DIR}/sandboxes.tar.gz \
 && rm -rf ${PROJECT_DIR}/fastqc \
 && rm -rf ${PROJECT_DIR}/multiqc \
 && rm -rf ${PROJECT_DIR}/.github \
 && rm -rf ${PROJECT_DIR}/.vscode \
 && rm -rf ${PROJECT_DIR}/samples \
 && rm -rf ${PROJECT_DIR}/tests \
 && rm -rf ${PROJECT_DIR}/docs

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