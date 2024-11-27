process STATICHTML {
    label 'process_single'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path(support_file_path)
    path(json_files)
    path(run_ID_ch)

    output:
    path("*.{html,xlsx,fasta}"), emit: reports
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    touch ${json_files}
    static_report.py -d ./ -r ${run_ID_ch} -l ${support_file_path}

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
