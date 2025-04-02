process SUBSAMPLEPAIREDREADS {
    tag "${sample}"
    label 'process_medium'

    container 'cdcgov/bbtools:v39.01-alpine'

    input:
    tuple val(sample), path(R1), path(R2), val(target), path(primers)

    output:
    tuple val(sample), path('*_subsampled_R1.fastq'), path('*_subsampled_R2.fastq'), path(primers), emit: subsampled_fastq
    path '*.reformat.stdout.log', emit: subsample_log_out
    path '*.reformat.stderr.log', emit: subsample_log_err
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    reformat.sh \\
        in1=${R1} \\
        in2=${R2} \\
        out1=${sample}_subsampled_R1.fastq \\
        out2=${sample}_subsampled_R2.fastq \\
        samplereadstarget=${target} \\
        tossbrokenreads \\
        1> ${sample}.reformat.stdout.log \\
        2> ${sample}.reformat.stderr.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subsamplepairedreads: \$(bbtools --version |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subsamplepairedreads: \$(bbtools --version |& sed '1!d ; s/bbtools //')
    END_VERSIONS
    """
}
