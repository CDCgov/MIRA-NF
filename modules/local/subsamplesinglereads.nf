process SUBSAMPLESINGLEREADS {
    tag { "${sample}" }
    label 'process_low'
    container 'staphb/bbtools:39.01'

    publishDir "${params.outdir}/IRMA", pattern: '*.fastq', mode: 'copy'
    publishDir "${params.outdir}/logs", pattern: '*.log', mode: 'copy'

    input:
    tuple val(sample), val(barcode), path(fastq_files), val(target)

    output:
    tuple val(sample), val(barcode), path('*_subsampled.fastq'), emit: subsampled_fastq
    path '*.reformat.stdout.log', emit: subsample_log_out
    path '*.reformat.stderr.log', emit: subsample_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    reformat.sh \\
        in=${fastq_files} \\
        out=${sample}_subsampled.fastq \\
        samplereadstarget=${target} \\
        qin=33 \\
        tossbrokenreads \\
        1> ${sample}.${barcode}.reformat.stdout.log \\
        2> ${sample}.${barcode}.reformat.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subsamplesinglereads: \$(bbtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subsamplesinglereads: \$(bbtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
