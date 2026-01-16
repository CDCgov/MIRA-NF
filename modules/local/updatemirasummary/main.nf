process UPDATEMIRASUMMARY {

    label 'process_single'

    container 'cdcgov/mira-oxide:v1.3.1'

    input:
    path summary
    path nextclade_tsv_files
    val virus
    val runid


    output:
    path('*.csv'), emit: summary_csv
    path('*.parq', emit: summary_parq, optional: true)
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def parquet_args = params.parquet_files ? '-f' : ''

    """
    mkdir nextclade
    cp ${nextclade_tsv_files} ./nextclade

    mira-oxide summary-report-update \\
        -s ${summary} \\
        -i ./nextclade \\
        -v ${virus} \\
        -r ${runid} \\
        -o ./ \\
        ${parquet_args} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": updatemirasummary: mira-oxide \$(mira-oxide --version |& sed '1!d; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    echo $args

    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": updatemirasummary: mira-oxide \$(mira-oxide --version |& sed '1!d; s/python3 //')
    END_VERSIONS
    """
}
