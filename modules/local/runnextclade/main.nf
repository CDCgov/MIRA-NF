process RUNNEXTCLADE {
    tag "${dataset_name}"

    label 'process_medium'
    container 'nextstrain/nextclade:3.18.1'

    input:
    tuple val(dataset_name), path(nextclade_fastq_files), path(nextclade_dataset)

    output:
    tuple val(dataset_name), path("${prefix}.csv")           , optional:true, emit: csv
    tuple val(dataset_name), path("${prefix}.errors.csv")    , optional:true, emit: csv_errors
    tuple val(dataset_name), path("${prefix}.insertions.csv"), optional:true, emit: csv_insertions
    tuple val(dataset_name), path("${prefix}.tsv")           , optional:true, emit: tsv
    tuple val(dataset_name), path("${prefix}.json")          , optional:true, emit: json
    tuple val(dataset_name), path("${prefix}.auspice.json")  , optional:true, emit: json_auspice
    tuple val(dataset_name), path("${prefix}.ndjson")        , optional:true, emit: ndjson
    tuple val(dataset_name), path("${prefix}.aligned.fasta") , optional:true, emit: fasta_aligned
    tuple val(dataset_name), path("*_translation.*.fasta")   , optional:true, emit: fasta_translation
    tuple val(dataset_name), path("${prefix}.nwk")           , optional:true, emit: nwk
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

    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        runnextclade: \$(runnextclade --version)
    END_VERSIONS
    """
}
