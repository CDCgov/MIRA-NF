process SUBSAMPLEPAIREDREADS {
    tag "${sample}"
    label 'process_medium'

    container 'ghcr.io/cdcgov/irma-core:v0.6.1'

    input:
    tuple val(sample), path(R1), path(R2), val(target), path(primers), val(primer_kmer_len), val(primer_restrict_window)

    output:
    tuple val(sample), path('*_subsampled_R1.fastq'), path('*_subsampled_R2.fastq'), path(primers), val(primer_kmer_len), val(primer_restrict_window), emit: subsampled_fastq
    path '*.subsampler.stdout.log', emit: subsample_log_out
    path '*.subsampler.stderr.log', emit: subsample_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    irma-core sampler \\
        ${R1} \\
        ${R2} \\
        -1 ${sample}_subsampled_R1.fastq \\
        -2 ${sample}_subsampled_R2.fastq \\
        --subsample-target ${target} \\
        1> ${sample}.subsampler.stdout.log \\
        2> ${sample}.subsampler.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subsamplepairedreads: \$(irma-core --version |& sed '1!d ; s/irma-core //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subsamplepairedreads: \$(irma-core --version |& sed '1!d ; s/irma-core //')
    END_VERSIONS
    """
}
