process FINDCHEMISTRYO {
    tag { "finding chemistry parameters for ${sample}" }
    label 'process_single'

    conda 'conda-forge::python=3.8.3'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"

    input:
    tuple val(sample), val(barcode), path(fastq), path(runid)

    output:
    path "${sample}_chemistry.csv", emit: sample_chem_csv
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${projectDir}/bin/find_chemistry_o.py -s "${sample}" -q "${fastq}" -r "${runid}" -e "${params.e}" -p "${projectDir}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        findchemistryo: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        findchemistryo: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """
}
