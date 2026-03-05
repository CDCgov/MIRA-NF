####################################################################################################
# BASE IMAGE
####################################################################################################
FROM alpine:3.22 AS base

# Required certs for apk update
COPY .certs/min-cdc-bundle-ca.crt /etc/ssl/certs/ca.crt
COPY .certs/min-cdc-bundle-ca.crt /root/ca.crt

# Put certs in /etc/ssl/certs location
RUN cat /etc/ssl/certs/ca.crt >> /etc/ssl/certs/ca-certificates.crt

# Install system libraries
RUN apk update && apk add --no-cache \
    bash \
    vim \
    tar \
    curl \
    openjdk17-jre \
    dos2unix

# Project directory
ENV PROJECT_DIR=/mira-nf

# Copy project files
COPY . ${PROJECT_DIR}

############# Install nextflow packages ##################

# Create nextflow directories
RUN mkdir -p /home/xpa3/.nextflow/framework/25.10.4

# Pull Nextflow
RUN curl -L https://get.nextflow.io -o /usr/local/bin/nextflow --cacert /etc/ssl/certs/ca.crt \
    && chmod +x /usr/local/bin/nextflow

# Get Java helper
RUN curl -L https://www.nextflow.io/releases/v25.10.4/nextflow-25.10.4-one.jar \
    -o /root/.nextflow/framework/25.10.4/nextflow-25.10.4-one.jar \
    --cacert /root/ca.crt

RUN nextflow -version

# Copy script
COPY MIRA_nextflow.sh ${PROJECT_DIR}/MIRA_nextflow.sh

# Convert Windows line endings
RUN dos2unix ${PROJECT_DIR}/MIRA_nextflow.sh

# Allow execution
RUN chmod +x ${PROJECT_DIR}/MIRA_nextflow.sh

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