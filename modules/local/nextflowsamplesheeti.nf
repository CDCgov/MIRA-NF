process NEXTFLOWSAMPLESHEETI {
    tag 'Generating the samplesheet for nextflow'
    label 'process_single'
    container 'cdcgov/spyne:latest'

    publishDir "${params.outdir}", mode: 'copy'

    input:
    path samplesheet
    path run_ID
    val experiment_type

    input:
    path samplesheet
    path run_ID
    val experiment_type

    // TODO nf-core: List additional required output channels/values here
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    #Removing if previous made
    if [ -e ${launchDir}/summary.xlsx ]; then
    rm ${launchDir}/summary.xlsx
    fi
    #Set up so that email sends whether workflow finishes or not
    cp ${launchDir}/assets/summary.xlsx ${launchDir}/summary.xlsx
    #Create nf samplesheet
    python3 ${launchDir}/bin/create_nextflow_samplesheet_i.py -s "${params.s}" -r "${params.r}" -e "${experiment_type}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflowsamplesheeti: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nextflowsamplesheeti: \$(python --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
