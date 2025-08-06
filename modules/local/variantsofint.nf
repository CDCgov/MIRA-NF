process VARIANTSOFINT {
    label 'process_low'
    container 'cdcgov/mira-oxide:latest'

    input:
    path dais_seq_output
    path ref_table
    path variant_of_int_table

    output:
    path "*", emit: variant_of_int
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

   """
    mira-oxide variants-of-interest -i ${dais_seq_output} -r ${ref_table} -o variants_of_interest.csv -m ${variant_of_int_table}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        variantsofint: \$(rustc --version |& sed '1!d ; s/rustc //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        variantsofint: \$(rustc --version |& sed '1!d ; s/rustc //')
    END_VERSIONS
    """
}
