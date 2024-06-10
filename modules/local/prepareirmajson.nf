process PREPAREIRMAJSON {
    tag 'Creating Plotly-Dash readable figures and tables for IRMA-SPY'
    container 'cdcgov/spyne:latest'
    label 'process_low'

    input:
    val x

    output:
    val x
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${launchDir}/bin/prepareIRMAjson.py ${params.r}/IRMA ${params.s} illumina flu

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prepareirmajson: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prepareirmajson: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
