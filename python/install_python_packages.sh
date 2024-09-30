
#!/bin/bash
# Wrapper to install python packages 

# Path to requirement file
PROJECT_DIR=${PROJECT_DIR:-/mira-nf}
requirement_file=${PROJECT_DIR}/python/requirements.txt

# Extract requirement_file to install each python package
if [[ -f ${requirement_file} ]]
then

	echo ${PROJECT_DIR}

	echo "Create python environment"

	python3 -m venv ${PROJECT_DIR}

	echo "Install python packages"

	${PROJECT_DIR}/bin/pip install --no-cache-dir -r ${requirement_file}
	
	echo "Done"

fi

