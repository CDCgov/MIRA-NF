process NEXTFLOWSAMPLESHEETI {
    label 'process_single'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path samplesheet
    path fastq_files
    val experiment_type

    output:
    path 'nextflow_samplesheet.csv', emit: nf_samplesheet
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    #Create nf samplesheet
    create_nextflow_samplesheet_i.py -s "${samplesheet}" -r "${params.outdir}" -e "${experiment_type}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflowsamplesheeti: \$(python3 --version |& sed '1!d ; s/python //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflowsamplesheeti: \$(python3 --version |& sed '1!d ; /python //')
    END_VERSIONS
    """
}
