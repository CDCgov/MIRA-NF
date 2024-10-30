process STAGES3FILES {
    tag 'stage s3 files to local disk '
    label 'stage_s3_files'

    conda 'conda-forge::python=3.8.3'
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3'}"

    input:
    val(runid)
    val(folder)
    path(fastq_file)

    output:
    path("./${folder}")

    script:
    """
    echo "Staging file to ./${folder}"
    if [ -d -e ./${folder}]; then
    rm -r ./${folder}
    fi
    mkdir -p ./${folder}
    cp ${fastq_file} ./${folder}
    """
}
