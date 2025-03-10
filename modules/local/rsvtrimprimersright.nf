process RSVTRIMPRIMERSRIGHT {
    tag "${sample}"
    label 'process_medium'

    container 'cdcgov/mira-nf:bbtools-alpine'

    publishDir "${params.outdir}/IRMA", pattern: '*.fastq', mode: 'copy'
    publishDir "${params.outdir}/logs", pattern: '*.log', mode: 'copy'

    input:
    tuple val(sample), path(ltrim_fastq_1), path(ltrim_fastq_2), path(primers)

    output:
    tuple val(sample), path('*ptrim_lr_R1.fastq'), path('*ptrim_lr_R2.fastq'), emit: trim_lr_fastqs
    path '*.primertrim_right.stdout.log', emit: primertrim_r_log_out
    path '*.primertrim_right.stderr.log', emit: primertrim_r_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    bbduk.sh \\
        in1=${ltrim_fastq_1} \\
        in2=${ltrim_fastq_2} \\
        out1=${sample}_ptrim_lr_R1.fastq \\
        out2=${sample}_ptrim_lr_R2.fastq \\
        ktrim=r \\
        trimpolyg=10 \\
        rcomp=t \\
        trimq=0 \\
        hdist=1 \\
        mm=f \\
        ref=${primers} \\
        mink=8 \\
        minlength=0 \\
        k=19 \\
        restrictright=35 \\
        1> ${sample}.primertrim_right.stdout.log \\
        2> ${sample}.primertrim_right.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimprimersleft: \$(bbversion.sh --version |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimprimersleft: \$(bbversion --version |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """
}

