process IRMA {
    tag "${sample}"

    label 'process_high'
    container 'cdcgov/irma:v1.2.1'

    input:
    tuple val(sample), path(subsampled_fastq_files), val(irma_custom_0), val(irma_custom_1), val(module)

    output:
    tuple val(sample), path('*') , emit: outputs
    path 'versions.yml' , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    ${irma_custom_0}

    IRMA \\
        ${module} \\
        ${subsampled_fastq_files} \\
        ${sample} \\
        ${irma_custom_1} \\
        2> ${sample}.irma.stderr.log | tee -a ${sample}.irma.stdout.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        irma: \$(echo \$(IRMA | grep -o "v[0-9][^ ]*" | cut -c 2-))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        irma: \$(echo \$(IRMA | grep -o "v[0-9][^ ]*" | cut -c 2-))
    END_VERSIONS
    """
}
