process UPDATEMIRASUMMARY {

    label 'process_single'

    container 'cdcgov/mira-oxide:v1.4.0'

    input:
    path summary
    tuple val(dataset_name), val(tag), path(nextclade_tsv_files)
    val virus
    val runid
    path nextclade_version

    output:
    path ('*.csv'), emit: summary_csv
    path '*.parq', emit: summary_parq, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def parquet_args = params.parquet_files ? '-f' : ''

    """
    # Read Nextclade version from file
    nextclade_version=\$(cat ${nextclade_version})

    mkdir nextclade
    cp ${nextclade_tsv_files} ./nextclade

    mira-oxide summary-report-update \\
        -s ${summary} \\
        -i ./nextclade \\
        -v ${virus} \\
        -r ${runid} \\
        -o ./ \\
        -n $nextclade_version \\
        -d ${dataset_name} \\
        -t ${tag} \\
        ${parquet_args} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": updatemirasummary: mira-oxide \$(mira-oxide --version |& sed '1!d; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    echo ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": updatemirasummary: mira-oxide \$(mira-oxide --version |& sed '1!d; s/python3 //')
    END_VERSIONS
    """
}
