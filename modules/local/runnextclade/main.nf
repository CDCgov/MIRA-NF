process RUNNEXTCLADE {
    tag "${dataset_name}"

    label 'process_medium'
    container 'nextstrain/nextclade:3.21.2'

    input:
    tuple val(dataset_name), val(tag), path(nextclade_fastq_files), path(nextclade_dataset)

    output:
    tuple val(dataset_name), val(tag), optional: true, emit: nextclade_metadata
    path ("${dataset_name}.tsv"), optional: true, emit: tsv
    path ("${dataset_name}.csv"), optional: true, emit: csv
    tuple val(dataset_name), path("${dataset_name}.json"), optional: true, emit: json
    tuple val(dataset_name), path("${dataset_name}.auspice.json"), optional: true, emit: json_auspice
    tuple val(dataset_name), path("${dataset_name}.ndjson"), optional: true, emit: ndjson
    tuple val(dataset_name), path("${dataset_name}.aligned.fasta"), optional: true, emit: fasta_aligned
    tuple val(dataset_name), path("*_translation.*.fasta"), optional: true, emit: fasta_translation
    tuple val(dataset_name), path("${dataset_name}.nwk"), optional: true, emit: nwk
    path ("nextclade_version.txt"), emit: nextclade_version
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    nextclade \\
        run \\
        --jobs ${task.cpus} \\
        --input-dataset ${nextclade_dataset} \\
        --output-all ./ \\
        --output-basename ${dataset_name} \\
        ${nextclade_fastq_files} \\
        ${args}

    # Capture Nextclade version for summary.cv in next module
    NEXTCLADE_VERSION=\$(nextclade --version 2>&1 | sed 's/^.*nextclade //; s/ .*\$//')
    echo \$NEXTCLADE_VERSION > nextclade_version.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": runnextclade: nextclade \$NEXTCLADE_VERSION
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    echo ${args}

    NEXTCLADE_VERSION=\$(nextclade --version 2>&1 | sed 's/^.*nextclade //; s/ .*\$//')
    echo \$NEXTCLADE_VERSION > nextclade_version.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": runnextclade: nextclade \$NEXTCLADE_VERSION
    END_VERSIONS
    """
}
