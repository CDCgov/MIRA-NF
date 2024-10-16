process TRIMLEFT {
    tag "${sample}"
    label 'process_medium'

    container 'cdcgov/mira-nf:bbtools-alpine'

    input:
    tuple val(sample), val(barcode), path(subsample_file_path), val(seq_f)

    output:
    tuple val(sample), val(barcode), path('*bartrim_l.fastq'), emit: trim_l_fastq
    path '*.trim_left.stdout.log', emit: trim_l_log_out
    path '*.trim_left.stderr.log', emit: trim_l_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    bbduk.sh \\
        in=${subsample_file_path} \\
        out=${sample}_bartrim_l.fastq \\
        hdist=3 \\
        literal=${seq_f} \\
        ktrim=l \\
        k=17 \\
        qin=33 \\
        rcomp=f \\
        1> ${sample}.${barcode}.trim_left.stdout.log \\
        2> ${sample}.${barcode}.trim_left.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimleft_bbduk: \$(bbversion.sh |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimleft_bbduk: \$(bbversion.sh |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """
}
