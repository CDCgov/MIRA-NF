
#!/bin/bash
# Wrapper to install downloaded packages 

PROJECT_DIR=${PROJECT_DIR:-"/bbtools"}
bbtools_orig=${PROJECT_DIR}/bbtools_file.txt
bbtools_clean=${PROJECT_DIR}/bbtools_file_clean.txt

# Make the bbtools directory exits, if not, create it
if [[ ! -d ${PROJECT_DIR} ]]
then
	mkdir ${PROJECT_DIR}
fi

# Extract bbmap package to the bbtools directory
if [[ -f ${bbtools_orig} ]]
then

	echo "Install bbtools"

	# Remove blank lines from the file and save a cleaner version of it
	awk NF < ${bbtools_orig} > ${bbtools_clean}

	# Get number of rows in bbtools_file_clean.txt
	n=`wc -l < ${bbtools_clean}`
	i=1

	# Get the file and install the package
	while [[ i -le $n ]];
	do
		echo $i
		file=$(head -${i} ${bbtools_clean} | tail -1 | sed 's,\r,,g')
		echo $file
		# Check if file exists
		if [[ -f ${PROJECT_DIR}/${file} ]]
		then
			echo "extract bbmap"
			tar -zvxf ${PROJECT_DIR}/${file} -C ${PROJECT_DIR}
		fi
		# Go to next file
		i=$(($i+1))
	done
	
	# return message to keep the process going
	echo "Done"

fi
