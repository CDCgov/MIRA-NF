process STATICHTML {
    tag 'Creating static HTML output'
    label 'process_single'
    container 'cdcgov/mira:latest'

    publishDir "${params.outdir}", mode: 'copy'

    input:
    val x
    val run_ID_ch

    output:
    path("*"), emit: html
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${launchDir}/bin/static_report.py -d ${run_ID_ch} -l ${launchDir}

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
