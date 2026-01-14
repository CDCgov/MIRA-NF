process PREPAREMIRAREPORTS {
    label 'process_low'

    container 'cdcgov/mira-oxide:v1.3.1'

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
    path('*summary', emit: summary_csv, optional: true)
    path('*.parq', emit: parquet_files, optional: true)
    path('nextclade_*.fasta', emit: nextclade_fasta_files, optional: true)
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def parquet_args = params.parquet_files ? '-f' : ''
    def summary_passing = params.nextclade ? 'cat mira_*_summary.csv > mira_summary' : ''

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
        ${parquet_args} \\
        ${args}

    ${summary_passing}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": preparemirareports: mira-oxide \$(mira-oxide --version |& sed '1!d; s/mira-oxide //')
    END_VERSIONS
    """

    stub:
    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": preparemirareports: mira-oxide \$(mira-oxide --version |& sed '1!d; s/mira-oxide //')
    END_VERSIONS
    """
}

