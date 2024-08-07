process NEXTFLOWSAMPLESHEETO {
    tag 'Generating the samplesheet for nextflow'
    label 'process_single'

    container 'cdcgov/mira-nf:latest'

    input:
    path samplesheet
    path run_ID
    val experiment_type
    path('*')

    output:
    path 'nextflow_samplesheet.csv', emit: nf_samplesheet
    path 'versions.yml' , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${projectDir}/bin/create_nextflow_samplesheet_o.py -s "${params.input}" -r "${params.runpath}" -e "${experiment_type}"

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
