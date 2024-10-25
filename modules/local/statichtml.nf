process STATICHTML {
    label 'process_single'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path(json_files)
    val run_ID_ch

    output:
    path("*.{html,xlsx}"), emit: html
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    touch ${json_files}
    python3 ${projectDir}/bin/static_report.py -d ./ -r ${run_ID_ch} -l ${projectDir}

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
