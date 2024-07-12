process PREPAREIRMAJSON {
    tag 'Creating Plotly-Dash readable figures and tables for IRMA-SPY'
    container 'cdcgov/spyne:latest'
    label 'process_low'
    label 'error_retry'

    publishDir "${params.outdir}/dash-json", pattern: '*.json', mode: 'copy'

    input:
    val x
    val platform
    val virus

    output:
    path('*.json') , emit: dash_json
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${projectDir}/bin/prepareIRMAjson.py ${params.outdir}/IRMA ${params.input} ${platform} ${virus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prepareirmajson: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prepareirmajson: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """
}
