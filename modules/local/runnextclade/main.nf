process RUNNEXTCLADE {
    tag "${dataset_name}"

    label 'process_medium'
    container 'nextstrain/nextclade:3.18.1'

    input:
    tuple val(dataset_name), path(nextclade_fastq_files), path(nextclade_dataset)

    output:
    tuple val(dataset_name), path("${dataset_name}.csv")           , optional:true, emit: csv
    path("${dataset_name}.tsv")           , optional:true, emit: tsv
    tuple val(dataset_name), path("${dataset_name}.json")          , optional:true, emit: json
    tuple val(dataset_name), path("${dataset_name}.auspice.json")  , optional:true, emit: json_auspice
    tuple val(dataset_name), path("${dataset_name}.ndjson")        , optional:true, emit: ndjson
    tuple val(dataset_name), path("${dataset_name}.aligned.fasta") , optional:true, emit: fasta_aligned
    tuple val(dataset_name), path("*_translation.*.fasta")   , optional:true, emit: fasta_translation
    tuple val(dataset_name), path("${dataset_name}.nwk")           , optional:true, emit: nwk
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

    """
    echo $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        runnextclade: \$(runnextclade --version)
    END_VERSIONS
    """
}
