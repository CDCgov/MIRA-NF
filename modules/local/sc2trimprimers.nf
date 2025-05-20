process SC2TRIMPRIMERS {
    tag "${sample}"
    label 'process_medium'

    container 'ghcr.io/cdcgov/irma-core:v0.4.3'

    publishDir "${params.outdir}/IRMA", pattern: '*.fastq', mode: 'copy'
    publishDir "${params.outdir}/logs", pattern: '*.log', mode: 'copy'

    input:
    tuple val(sample), path(subsampled_fastq_1), path(subsampled_fastq_2), path(primers), val(primer_kmer_len), val(primer_restrict_window)

    output:
    tuple val(sample), path('*ptrim_R1.fastq'), path('*ptrim_R2.fastq'), emit: trim_fastqs
    path '*.primertrim.stdout.log', emit: primertrim_log_out
    path '*.primertrim.stderr.log', emit: primertrim_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    irma-core trimmer  \\
        ${subsampled_fastq_1} \\
	    ${subsampled_fastq_2} \\
	    -1 ${sample}_ptrim_R1.fastq \\
	    -2 ${sample}_ptrim_R2.fastq \\
	    --primer-trim ${primers} \\
	    --p-end B \\
	    --polyg-trim 10 \\
	    --p-fuzzy \\
	    --p-kmer-length ${primer_kmer_len} \\
	    --p-restrict ${primer_restrict_window} \\
        1> ${sample}.primertrim.stdout.log \\
        2> ${sample}.primertrim.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        primertrim_irma-core: \$(irma-core --version |& sed '1!d ; s/irma-core //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sc2trimprimers_irma-core: \$(irma-core --version |& sed '1!d ; s/irma-core //')
    END_VERSIONS
    """
}