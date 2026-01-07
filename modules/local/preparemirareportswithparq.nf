process PREPAREMIRAREPORTSWITHPARQ {
    label 'process_low'

    container 'cdcgov/mira-oxide:latest'

    input:
    path dais_outputs
    path support_file_path
    path irma_dir
    path samplesheet
    path qc_path
    val  platform
    val  virus
    val  irma_config_type
    val  runid


    output:
    path('*'), emit: all_files
    path('*summary.csv'), emit: summary_csv
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    mira-oxide prepare-mira-reports \\
        -w ${support_file_path} \\
        -s ${samplesheet} \\
        -i ${irma_dir} \\
        -p ${platform} \\
        -v ${virus} \\
        -q ${qc_path} \\
        -c ${irma_config_type} \\
        -r ${runid} \\
        -o ./ \\
        -f \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
      preparemirareportswithparq: \$(mira-oxide --version |& sed '1!d; s/python3 //')
    END_VERSIONS
    """

    stub:
    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
      preparemirareportswithparq: stub
    END_VERSIONS
    """
}

