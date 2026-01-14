process DAISRIBOSOME {
    label 'process_medium'

    container 'cdcgov/dais-ribosome:v1.6.1'
    // The container binding for this step has been moved to the module.config and omics.config to allow for different binding based on environment

    input:
    path input_fasta
    val dais_module

    output:
    path('*.{seq,gen,ins,del}') , emit: dais_outputs
    path('*.seq') , emit: dais_seq_output
    path 'versions.yml' , emit: versions

    script:
    def args = task.ext.args ?: ''

    shell:
    '''
    base_name=$(basename !{input_fasta})
    dais_out="${base_name%_input*}"
    ribosome --module !{dais_module} !{input_fasta} ${dais_out}.seq ${dais_out}.ins ${dais_out}.del ${dais_out}.gen

    echo "!{task.process}: daisribosome: cdcgov/dais-ribosome:v1.6.1" > versions.yml
    '''
}
