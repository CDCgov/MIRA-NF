process VARIANTSOFINT {
    label 'process_low'
    container 'cdcgov/mira-oxide:v1.3.1'

    input:
    path dais_seq_output
    path ref_table
    path variant_of_int_table
    val virus

    output:
    path "*", emit: variant_of_int
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

   """
    mira-oxide variants-of-interest -i ${dais_seq_output} -r ${ref_table} -o variants_of_interest.csv -m ${variant_of_int_table} -v ${virus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        variantsofint: \$(mira-oxide --version |& sed '1!d ; s/mira-oxide //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        variantsofint: \$(mira-oxide --version |& sed '1!d ; s/mira-oxide //')
    END_VERSIONS
    """
}
