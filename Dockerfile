
# Create a build argument
ARG BUILD_STAGE
ARG BUILD_STAGE=${BUILD_STAGE:-prod}

############# Build Stage: Dependencies ##################

# Start from a base image
FROM --platform=linux/amd64 ubuntu:focal as base

# Define a system argument
ARG DEBIAN_FRONTEND=noninteractive

# Install system libraries of general use
RUN apt-get update --allow-releaseinfo-change && apt-get install --no-install-recommends -y \
    build-essential \ 
    iptables \
    libdevmapper1.02.1 \
    python3.7\
    python3-pip \
    python3-setuptools \
    python3-dev \
    dpkg \
    sudo \
    wget \
    curl \
    dos2unix

############# Build Stage: Development ##################

# Build from the base image for dev
FROM base as dev

# Create working directory variable
ENV WORKDIR=/data

# Create a stage enviroment
ENV STAGE=dev

############# Build Stage: Production ##################

# Build from the base image for prod
FROM base as prod

# Create working directory variable
ENV WORKDIR=/data

# Create a stage enviroment
ENV STAGE=prod

# Copy all scripts to docker images
COPY . /mira-nf

############# Build Stage: Final ##################

# Build the final image 
FROM ${BUILD_STAGE} as final

# Set up volume directory in docker
VOLUME ${WORKDIR}

# Set up working directory in docker
WORKDIR ${WORKDIR}

# Allow permission to read and write files to current working directory
RUN chmod -R a+rwx ${WORKDIR}

############# Install python packages ##################

# Copy all files to docker images
COPY requirements.txt /mira-nf/requirements.txt

# Install python requirements
RUN pip3 install --no-cache-dir -r /mira-nf/requirements.txt

############# Run mira-nf ##################

# Allow permission to read and write files to mira-nf directory
RUN chmod -R a+rwx /mira-nf

# Clean up
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Export bash script to path
ENV PATH "$PATH:/mira-nf"
