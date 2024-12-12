process PREPAREIRMAJSON {
    label 'process_low'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path dais_outputs
    path support_file_path
    path irma_dir
    path nf_samplesheet
    val platform
    val virus
    val irma_config_type
    path qc_path_ch

    output:
    path('*.{fasta,json}') , emit: dash_json_and_fastqs
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    cp ${qc_path_ch} ${irma_dir}/pipeline_info/qc_pass_fail_settings.yaml
    prepareIRMAjson.py ${support_file_path} ${irma_dir} ${nf_samplesheet} ${platform} ${virus} ${irma_config_type}

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
