process POSITIONSOFINT {
    label 'process_low'
    container 'cdcgov/mira-oxide:v1.4.0'

    input:
    path dais_seq_output
    path ref_table
    path position_of_int_table
    val virus

    output:
    path "*", emit: position_of_int
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    mira-oxide positions-of-interest -i ${dais_seq_output} -r ${ref_table} -o positions_of_interest.csv -m ${position_of_int_table}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": positionsofint: mira-oxide \$(mira-oxide --version |& sed '1!d ; s/mira-oxide //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}": positionsofint: mira-oxide \$(mira-oxide --version |& sed '1!d ; s/mira-oxide //')
    END_VERSIONS
    """
}
