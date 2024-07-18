process DAISRIBOSOME {
    tag 'Translating sequences into open reading frames (ORFs) with DAIS-Ribosome'
    label 'process_medium'
    container 'cdcgov/dais-ribosome:v1.3.2'
    containerOptions '--bind ${launchDir}/tmp:/dais-ribosome/workdir --bind ${launchDir}/tmp:/dais-ribosome/lib/sswsort/workdir/'

    publishDir "${params.outdir}/IRMA/dais_results", pattern: '*.del', mode: 'copy'
    publishDir "${params.outdir}/IRMA/dais_results", pattern: '*.ins', mode: 'copy'
    publishDir "${params.outdir}/IRMA/dais_results", pattern: '*.seq', mode: 'copy'

    input:
    path input_fasta
    val dais_module

    output:
    path('*') , emit: dais_outputs
    path 'versions.yml' , emit: versions

    script:
    def args = task.ext.args ?: ''

    shell:
    '''
    base_name=$(basename !{input_fasta})
    dais_out="${base_name%_input*}"
    ribosome --module !{dais_module} !{input_fasta} ${dais_out}.seq ${dais_out}.ins ${dais_out}.del

    echo "daisrinosome: cdcgov/dais-ribosome:v1.3.2" > versions.yml
    '''
}
