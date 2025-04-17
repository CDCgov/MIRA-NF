process BLASTN {
    tag "${sample}"

    label 'process_low'
    container 'cdcgov/blast:v2.13.0-alpine'

    input:
    tuple val(sample), path(input_fasta)

    output:
    path '*.txt', emit: blast
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    if [[ ! -s ${input_fasta} ]]; then
    touch blast_empty.txt
    fi
    if [[ -s ${input_fasta} ]]; then
    blastn \\
        -db /blast/blast-starsbioeditLAIVsw/starsbioeditLAIVsw \\
        -query ${input_fasta} \\
        -out blast_${sample}.txt
        fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blastn: \$(blastn -version |& sed '1!d ; s/blastn //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blastn: \$(blastn -version |& sed '1!d ; s/blastn //')
    END_VERSIONS
    """
}
