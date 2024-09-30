# Create an argument to pull a particular version of base image
ARG base_image
ARG base_image=${base_image:-debian:trixie-slim}

# Start from a base image
FROM ${base_image} as base

# Define a system argument
ARG DEBIAN_FRONTEND=noninteractive

# Install system libraries of general use
RUN apt-get update --allow-releaseinfo-change --fix-missing \
    && apt-get install --no-install-recommends -y \
    build-essential \ 
    iptables \
    python3 \
    python3-venv \
    python3-pip-whl \
    python3-setuptools-whl \
    ca-certificates \
    default-jre \
    default-jdk \
    vim \
    wget \
    curl \
    tar \
    dos2unix

# Create working directory variable
ENV WORKDIR=/data

# set a project directory
ENV PROJECT_DIR=/mira-nf

# Set up volume directory in docker
VOLUME ${WORKDIR}

# Set up working directory in docker
WORKDIR ${WORKDIR}

# Copy all scripts to docker images
COPY . ${PROJECT_DIR}

############# Install bbtools ##################

# Copy all files to docker images
COPY bbtools ${PROJECT_DIR}/bbtools

# Copy all files to docker images
COPY bbtools/install_bbtools.sh ${PROJECT_DIR}/bbtools/install_bbtools.sh

# Convert bash script from Windows style line endings to Unix-like control characters
RUN dos2unix ${PROJECT_DIR}/bbtools/install_bbtools.sh

# Allow permission to excute the bash script
RUN chmod a+x ${PROJECT_DIR}/bbtools/install_bbtools.sh

# Execute bash script to wget the file and tar the package
RUN bash ${PROJECT_DIR}/bbtools/install_bbtools.sh

############# Install python packages ##################

# Copy all files to docker images
COPY python ${PROJECT_DIR}/python

# Copy all files to docker images
COPY python/install_python_packages.sh ${PROJECT_DIR}/python/install_python_packages.sh

# Convert bash script from Windows style line endings to Unix-like control characters
RUN dos2unix ${PROJECT_DIR}/python/install_python_packages.sh

# Allow permission to excute the bash script
RUN chmod a+x ${PROJECT_DIR}/python/install_python_packages.sh

# Execute bash script to wget the file and tar the package
RUN bash ${PROJECT_DIR}/python/install_python_packages.sh

############# Run nextflow bash script ##################

# Copy all files to docker images
COPY MIRA_nextflow.sh ${PROJECT_DIR}/MIRA_nextflow.sh

# Convert spyne from Windows style line endings to Unix-like control characters
RUN dos2unix ${PROJECT_DIR}/MIRA_nextflow.sh

# Allow permission to excute the bash scripts
RUN chmod a+x ${PROJECT_DIR}/MIRA_nextflow.sh

# Clean up and remove unwanted files
RUN apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Export project directory to PATH
ENV PATH "$PATH:${PROJECT_DIR}"
