process CREATEDAISINPUT {
    tag { 'Collecting consensus genomes' }
    label 'process_single'

    input:
    val irma_out

    output:
    path('DAIS_ribosome_input.fasta')

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def folderPaths = irma_out.collect { "$it/amended_consensus/*" }.join(' ')

    """
    cat $folderPaths > DAIS_ribosome_input.fasta
    """
}
