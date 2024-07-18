process PASSFAILED {
    tag { "passing negatives for ${sample }" }
    label 'process_single'

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
