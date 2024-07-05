process CUTADAPT30 {
    tag { "${sample}" }
    label 'process_low'
    label 'error_retry'
    container 'cdcgov/spyne:latest'

    publishDir "${params.outdir}/IRMA", pattern: '*.fastq', mode: 'copy'
    publishDir "${params.outdir}/logs", pattern: '*.log', mode: 'copy'

    input:
    tuple val(sample), val(barcode), path(trim_lr_file_path)

    output:
    tuple val(sample), val(barcode), path('*bartrim_lr_cutadapt.fastq'), emit: cutadapt_fastq
    path '*.cutadapt.stdout.log', emit: cut_adapt_log_out
    path '*.cutadapt.stderr.log', emit: cut_adapt_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    cutadapt -u 30 -u -30 --output ${sample}_bartrim_lr_cutadapt.fastq ${sample}_bartrim_lr.fastq 1> ${sample}.${barcode}.cutadapt.stdout.log 2> ${sample}.${barcode}.cutadapt.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cutadapt30: \$(cutadapt --version |& sed '1!d ; s/cutadapt //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cutadapt30: \$(cutadapt --version |& sed '1!d ; s/cutadapt //')
    END_VERSIONS
    """
}
