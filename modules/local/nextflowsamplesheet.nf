process NEXTFLOWSAMPLESHEET {
    label 'process_single'

    container 'cdcgov/mira-oxide:v1.4.0'

    input:
    path samplesheet
    val fastq_files
    val experiment_type

    output:
    path 'nextflow_samplesheet.csv', emit: nf_samplesheet
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    if [[ "${experiment_type}" == *"Illumina"* ]]; then
        mira-oxide create-nextflow-samplesheet -s "${samplesheet}" -r "${fastq_files}" -e "${experiment_type}"
    elif [[ "${experiment_type}" == *"ONT"* ]]; then
        mira-oxide create-nextflow-samplesheet  -s "${samplesheet}" -r "${params.outdir}" -e "${experiment_type}"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": nextflowsamplesheet: \$(python3 --version |& sed '1!d ; s/python //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}": nextflowsamplesheet: \$(python3 --version |& sed '1!d ; /python //')
    END_VERSIONS
    """
}
