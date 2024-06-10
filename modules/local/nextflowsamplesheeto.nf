process NEXTFLOWSAMPLESHEETO {
    tag 'Generating the samplesheet for nextflow'
    label 'process_single'
    container 'cdcgov/spyne:latest'

    publishDir "${params.outdir}", mode: 'copy'

    input:
    path samplesheet
    path run_ID
    val experiment_type
    path('*')

    output:
    path 'nextflow_samplesheet.csv'
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${launchDir}/bin/create_nextflow_samplesheet_o.py -s "${params.input}" -r "${params.outdir}" -e "${experiment_type}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflowsamplesheeto: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflowsamplesheeto: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """
}
