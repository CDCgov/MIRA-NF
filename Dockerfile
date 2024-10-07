# Create an argument to pull a particular version of an image
ARG base_image
ARG base_image=${base_image:-python3.10-alpine-pyarrow}

####################################################################################################
# BASE IMAGE
####################################################################################################
FROM ${base_image} as base

# Required certs for apk update
COPY ca.crt /root/ca.crt

# Put certs in /etc/ssl/certs location
RUN cat /root/ca.crt >> /etc/ssl/certs/ca-certificates.crt

# Install system libraries of general use
RUN apk update \
  && apk add  \
    python3-dev \ 
    openjdk11 \
    bash \
    vim \
    tar \
    dos2unix \ 
    && pip install --upgrade pip

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
COPY requirements.txt /mira-nf/requirements.txt

# Install python requirements
RUN pip install --no-cache-dir -r /mira-nf/requirements.txt

############# Run nextflow bash script ##################

# Copy all files to docker images
COPY MIRA_nextflow.sh ${PROJECT_DIR}/MIRA_nextflow.sh

# Convert spyne from Windows style line endings to Unix-like control characters
RUN dos2unix ${PROJECT_DIR}/MIRA_nextflow.sh

# Allow permission to excute the bash scripts
RUN chmod a+x ${PROJECT_DIR}/MIRA_nextflow.sh

# Export project directory to PATH
ENV PATH "$PATH:${PROJECT_DIR}"

# Allow container to keep running when it starts
ENTRYPOINT ["/bin/bash", "-c", "tail -f /dev/null"]
