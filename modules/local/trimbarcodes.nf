process TRIMBARCODES {
    tag "${sample}"
    label 'process_medium'

    container 'ghcr.io/cdcgov/irma-core:v0.4.2'

    input:
    tuple val(sample), val(barcode), path(subsample_file_path), val(seq)

    output:
    tuple val(sample), val(barcode), path('*_trimmed.fastq'), emit: bartrim_fastq
    path '*.bartrim.stdout.log', emit: bartrim_log_out
    path '*.bartrim.stderr.log', emit: bartrim_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    irma-core trimmer  \\
        ${subsample_file_path} \\
	    -o ${sample}_trimmed.fastq \\
	    --barcode-trim ${seq} \\
	    --b-end b \\
	    --b-hdist 3 \\
	    --hard-trim 30 \\
        1> ${sample}.${barcode}.bartrim.stdout.log \\
        2> ${sample}.${barcode}.bartrim.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bartrim_irma-core: \$(irma-core --version |& sed '1!d ; s/irma-core //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bartrim_irma-core: \$(irma-core --version |& sed '1!d ; s/irma-core //')
    END_VERSIONS
    """
}
