process RSVTRIMPRIMERSLEFT {
    tag "${sample}"
    label 'process_medium'

    container 'cdcgov/mira-nf:bbtools-alpine'

    input:
    tuple val(sample), path(subsampled_fastq_1), path(subsampled_fastq_2), path(primers)

    output:
    tuple val(sample), path('*ptrim_l_R1.fastq'), path('*ptrim_l_R2.fastq'), path(primers), emit: trim_l_fastqs
    path '*.primertrim_left.stdout.log', emit: primertrim_l_log_out
    path '*.primertrim_left.stderr.log', emit: primertrim_l_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    bbduk.sh \\
        in=${subsampled_fastq_1} \\
        in2=${subsampled_fastq_2} \\
        out=${sample}_ptrim_l_R1.fastq \\
        out2=${sample}_ptrim_l_R2.fastq \\
        ktrim=l \\
        trimpolyg=10 \\
        mm=f \\
        hdist=1 \\
        rcomp=t \\
        ref=${primers} \\
        ordered=t \\
        minlength=0 \\
        k=19 \\
        mink=8 \\
        restrictleft=35 \\
        1> ${sample}.primertrim_left.stdout.log \\
        2> ${sample}.primertrim_left.stderr.log

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
        trimprimersleft: \$(bbversion.sh --version |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """
}
