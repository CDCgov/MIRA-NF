process SUBSAMPLESINGLEREADS {
    tag "${sample}"
    label 'process_medium'

    container 'ghcr.io/cdcgov/irma-core:v0.6.1'

    input:
    tuple val(sample), val(barcode), path(fastq_file), val(target)

    output:
    tuple val(sample), val(barcode), path('*_subsampled.fastq'), emit: subsampled_fastq
    path '*.subsampler.stdout.log', emit: subsample_log_out
    path '*.subsampler.stderr.log', emit: subsample_log_err
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    irma-core sampler \\
        ${fastq_file} \\
        -o ${sample}_subsampled.fastq \\
        --subsample-target ${target} \\
        1> ${sample}.${barcode}.subsampler.stdout.log \\
        2> ${sample}.${barcode}.subsampler.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": subsamplesinglereads: irma-core \$(irma-core --version |& sed '1!d ; s/irma-core //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        "${task.process}": subsamplesinglereads: irma-core \$(irma-core --version |& sed '1!d ; s/irma-core //')
    END_VERSIONS
    """
}
