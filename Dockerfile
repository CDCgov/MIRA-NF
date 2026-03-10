####################################################################################################
# BASE IMAGE
####################################################################################################
FROM debian:bookworm-slim AS builder

# Install CA packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    ca-certificates-java \
    openjdk-17-jre-headless \
    curl \
    wget \
    bash \
    vim \
    tar \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Add custom CA properly
COPY .certs/min-cdc-bundle-ca.crt /usr/local/share/ca-certificates/min-cdc-bundle-ca.crt

# For curl to work
RUN cat /usr/local/share/ca-certificates/min-cdc-bundle-ca.crt >> /etc/ssl/certs/ca.crt

# Update system + Java truststores
RUN update-ca-certificates

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

############# Install Docker ##################

RUN apt-get update && apt-get install -y --no-install-recommends docker.io

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