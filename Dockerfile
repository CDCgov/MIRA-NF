# Create an argument to pull a particular version of an image
ARG python_image
ARG python_image=${python_image:-mira-nf:pyarrow-alpine}

####################################################################################################
# BASE IMAGE
####################################################################################################
FROM ${python_image} as base

# Create environment variable to get base python version
ARG python_version
ENV python_version=${python_version:-python3.10}

# Required certs for apk update
COPY ca.crt /root/ca.crt

# Put certs in /etc/ssl/certs location
RUN cat /root/ca.crt >> /etc/ssl/certs/ca-certificates.crt

# Install system libraries of general use
RUN apk update && apk add --no-cache \
    bash \
    vim \
    tar \
    dos2unix \ 
    && pip install --upgrade pip

# Create working directory variable
ENV PROJECT_DIR=/mira-nf

# Copy all scripts to docker images
COPY . ${PROJECT_DIR}

############# Install python packages ##################

# Copy all files to docker images
COPY docker_files/requirements.txt ${PROJECT_DIR}/requirements.txt

# Install python requirements
RUN pip install --no-cache-dir -r ${PROJECT_DIR}/requirements.txt

############# Run nextflow bash script ##################

# Copy all files to docker images
COPY MIRA_nextflow.sh ${PROJECT_DIR}/MIRA_nextflow.sh

# Convert spyne from Windows style line endings to Unix-like control characters
RUN dos2unix ${PROJECT_DIR}/MIRA_nextflow.sh

# Allow permission to excute the bash scripts
RUN chmod a+x ${PROJECT_DIR}/MIRA_nextflow.sh

############# Fix vulnerablities pkgs ##################

# Copy all files to docker images
COPY docker_files/fixed_vulnerability_pkgs.txt ${PROJECT_DIR}/fixed_vulnerability_pkgs.txt

# Copy all files to docker images
COPY docker_files/fixed_vulnerability_pkgs.sh ${PROJECT_DIR}/fixed_vulnerability_pkgs.sh

# Convert bash script from Windows style line endings to Unix-like control characters
RUN dos2unix ${PROJECT_DIR}/fixed_vulnerability_pkgs.sh

# Allow permission to excute the bash script
RUN chmod a+x ${PROJECT_DIR}/fixed_vulnerability_pkgs.sh

# Execute bash script to wget the file and tar the package
RUN bash ${PROJECT_DIR}/fixed_vulnerability_pkgs.sh  

############# Remove vulnerability pkgs ##################

# Copy all files to docker images
COPY docker_files/remove_vulnerability_pkgs.txt ${PROJECT_DIR}/remove_vulnerability_pkgs.txt

# Copy all files to docker images
COPY docker_files/remove_vulnerability_pkgs.sh ${PROJECT_DIR}/remove_vulnerability_pkgs.sh

# Convert bash script from Windows style line endings to Unix-like control characters
RUN dos2unix ${PROJECT_DIR}/remove_vulnerability_pkgs.sh

# Allow permission to excute the bash script
RUN chmod a+x ${PROJECT_DIR}/remove_vulnerability_pkgs.sh

# Execute bash script to wget the file and tar the package
RUN bash ${PROJECT_DIR}/remove_vulnerability_pkgs.sh

############# Remove the vendor packages ##################

# Clean up and remove unwanted files
RUN rm -rf /usr/local/lib/${python_version}/site-packages/pip/_vendor \
    && rm -rf /usr/local/lib/${python_version}/site-packages/pipenv/patched/pip/_vendor \
    && rm -rf /usr/local/lib/${python_version}/site-packages/examples \
    && rm -rf ${PROJECT_DIR}/bbtools \
    && rm -rf ${PROJECT_DIR}/cutadapt \
    && rm -rf ${PROJECT_DIR}/fastqc \
    && rm -rf ${PROJECT_DIR}/multiqc \
    && rm -rf ${PROJECT_DIR}/pyarrow 

############# Set up working directory ##################

# Create working directory variable
ENV WORKDIR=/data

# Set up volume directory in docker
VOLUME ${WORKDIR}

# Set up working directory in docker
WORKDIR ${WORKDIR}    

# Export project directory to PATH
ENV PATH "$PATH:${PROJECT_DIR}"

