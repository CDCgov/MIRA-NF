process CONFIRMIRMAOUTPUT {
    tag "${sample}"
    label 'process_single'

    input:
    tuple val(sample), val(irma_dir)

    output:
    tuple val(sample), val(irma_dir), path("${sample}.irma.decision")

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    [ -d ${irma_dir}/amended_consensus ] &&
        [ \"\$(ls -A ${irma_dir}/amended_consensus)\" ] &&
         echo passed > ${sample}.irma.decision ||
         echo failed > ${sample}.irma.decision
    """
}
