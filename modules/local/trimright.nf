process TRIMRIGHT {
    tag "${sample}"
    label 'process_medium'

    container 'cdcgov/bbtools:v39.01-alpine'

    input:
    tuple val(sample), val(barcode), path(trim_l_file_path), val(seq_rc)

    output:
    tuple val(sample), val(barcode), path('*bartrim_lr.fastq'), emit: trim_r_fastq
    path '*.trim_right.stdout.log', emit: trim_r_log_out
    path '*.trim_right.stderr.log', emit: trim_r_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    bbduk.sh \\
        in=${trim_l_file_path} \\
        out=${sample}_bartrim_lr.fastq \\
        hdist=3 \\
        literal=${seq_rc} \\
        ktrim=r \\
        k=17 \\
        qin=33 \\
        rcomp=f \\
        1> ${sample}.${barcode}.trim_right.stdout.log \\
        2> ${sample}.${barcode}.trim_right.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimright_bbduk: \$(bbversion.sh |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimright_bbduk: \$(bbversion.sh |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """
}
