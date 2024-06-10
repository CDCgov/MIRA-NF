process PASSFAILED {
    tag { "passing negatives for ${sample }" }
    label 'process_single'
    publishDir "${params.outdir}/IRMA_negative", mode: 'copy'

    input:
    val(sample)

    output:
    path('*')

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    touch ${sample}
    """
}
