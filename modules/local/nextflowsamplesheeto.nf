process NEXTFLOWSAMPLESHEETO {
    label 'process_single'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path samplesheet
    path run_ID
    val experiment_type

    output:
    path 'nextflow_samplesheet.csv', emit: nf_samplesheet
    path 'versions.yml' , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    # AWS Healthomics requires a path to the samplesheet in order to stage the files for the pipeline
    create_nextflow_samplesheet_o.py -s "${samplesheet}" -r "${params.outdir}" -e "${experiment_type}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflowsamplesheeto: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflowsamplesheeto: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """
}
