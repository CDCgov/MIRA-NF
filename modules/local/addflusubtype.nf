process ADDFLUSUBTYPE {
    label 'process_single'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path irma_dir
    val run_name
    path aavars
    path input_summary

    output:
    path '*.csv', emit: updatedcsv
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    extract_subtypes.py ${irma_dir} ${aavars} ${input_summary} ${run_name}_summary.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        addflusubtype: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        addflusubtype: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
