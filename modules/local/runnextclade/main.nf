process RUNNEXTCLADE {
    tag "${dataset_name}"

    label 'process_medium'
    container 'nextstrain/nextclade:3.18.1'

    input:
    tuple val(dataset_name), path(nextclade_fastq_files), path(nextclade_dataset)

    output:
    tuple val(meta), path("${prefix}.csv")           , optional:true, emit: csv
    tuple val(meta), path("${prefix}.errors.csv")    , optional:true, emit: csv_errors
    tuple val(meta), path("${prefix}.insertions.csv"), optional:true, emit: csv_insertions
    tuple val(meta), path("${prefix}.tsv")           , optional:true, emit: tsv
    tuple val(meta), path("${prefix}.json")          , optional:true, emit: json
    tuple val(meta), path("${prefix}.auspice.json")  , optional:true, emit: json_auspice
    tuple val(meta), path("${prefix}.ndjson")        , optional:true, emit: ndjson
    tuple val(meta), path("${prefix}.aligned.fasta") , optional:true, emit: fasta_aligned
    tuple val(meta), path("*_translation.*.fasta")   , optional:true, emit: fasta_translation
    tuple val(meta), path("${prefix}.nwk")           , optional:true, emit: nwk
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    nextclade \\
        run \\
        --jobs $task.cpus \\
        --input-dataset ${nextclade_dataset}\\
        --output-all ./ \\
        --output-basename ${dataset_name} \\
        ${nextclade_fastq_files} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        runnextclade: \$(runnextclade --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    // TODO nf-core: If the module doesn't use arguments ($args), you SHOULD remove:
    //               - The definition of args `def args = task.ext.args ?: ''` above.
    //               - The use of the variable in the script `echo $args ` below.
    """
    echo $args

    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        runnextclade: \$(runnextclade --version)
    END_VERSIONS
    """
}
