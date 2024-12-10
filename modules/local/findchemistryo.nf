process FINDCHEMISTRYO {
    tag "${sample}"
    label 'process_single'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    tuple val(sample), val(barcode), path(fastq), path(runid)
    val read_counts
    val irma_config
    path(custom_irma_config)

    output:
    path "${sample}_chemistry.csv", emit: sample_chem_csv
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    find_chemistry_o.py -s "${sample}" -q "${fastq}" -r "${runid}" -e "${params.e}" -p "${projectDir}" -c "${read_counts}" -i ${irma_config} -g ${custom_irma_config}

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
