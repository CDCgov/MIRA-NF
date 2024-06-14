process NEXTFLOWSAMPLESHEETI {
    tag 'Generating the samplesheet for nextflow'
    label 'process_single'
    container 'cdcgov/spyne:latest'

    publishDir "${params.outdir}", pattern: '*.csv', mode: 'copy'

    input:
    path samplesheet
    val experiment_type

    output:
    path 'nextflow_samplesheet.csv', emit: nf_samplesheet
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    #Removing if previous made
    if [ -f -e ${launchDir}/summary.xlsx ]; then
    rm ${launchDir}/summary.xlsx
    fi
    #Set up so that email sends whether workflow finishes or not
    cp ${launchDir}/assets/summary.xlsx ${launchDir}/summary.xlsx
    #Create nf samplesheet
    python3 ${launchDir}/bin/create_nextflow_samplesheet_i.py -s "${samplesheet}" -r "${params.outdir}" -e "${experiment_type}"

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
