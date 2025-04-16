process CREATEBLASTNINPUT {
    tag "${sample}"
    label 'process_single'

    input:
    tuple val(sample), path(irma_out)

    output:
    tuple val(sample), path('*.fa'), emit: blastn_path

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    if [[ -f ${irma_out}/A_PB2.bam && ${irma_out}/amended_consensus/${sample}_1.fa ]]; then
    cp ${irma_out}/amended_consensus/${sample}_1.fa ./${sample}_1.fa
    fi
    if [[ -f ${irma_out}/B_PB2.bam && ${irma_out}/amended_consensus/${sample}_2.fa ]]; then
    cp ${irma_out}/amended_consensus/${sample}_2.fa ./${sample}_2.fa
    fi
    if [[ ! -f ${irma_out}/A_PB2.bam && ! -f ${irma_out}/B_PB2.bam ]]; then
    touch ./${sample}_empty.fa
    fi

    """
}
