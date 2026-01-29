process CONFIRMIRMAOUTPUT {
    tag "${sample}"
    label 'process_single'

    input:
    tuple val(sample), path('*')

    output:
    tuple val(sample), path("${sample}/"), path("${sample}.irma.decision")

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    [ -d ${sample}/amended_consensus ] &&
         [ \"\$(ls -A ${sample}/amended_consensus)\" ] &&
         echo passed > ${sample}.irma.decision ||
         echo failed > ${sample}.irma.decision
    """
}
