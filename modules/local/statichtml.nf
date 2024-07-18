process STATICHTML {
    tag 'Creating static HTML output'
    label 'process_single'

    container 'cdcgov/spyne-dev:v1.2.0'

    input:
    path json_files
    val run_ID_ch

    output:
    path("*"), emit: html
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${projectDir}/bin/static_report.py -d ${params.outdir} -r ${run_ID_ch} -l ${projectDir}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        statichtml: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        statichtml: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """
}
