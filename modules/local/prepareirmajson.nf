process PREPAREIRMAJSON {
    label 'process_low'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    val x
    path nf_samplesheet
    val platform
    val virus

    output:
    path('*') , emit: dash_json
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${projectDir}/bin/prepareIRMAjson.py ${projectDir} ${params.outdir} ${nf_samplesheet} ${platform} ${virus}

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
