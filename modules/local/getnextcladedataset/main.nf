 process GETNEXTCLADEDATASET {
    tag "${dataset}"

    label 'process_low'
    container 'nextstrain/nextclade:3.18.1'

    input:
    tuple path(nextclade_fastq_files), val(dataset), val (tag)

    output:
    tuple val(dataset), path(nextclade_fastq_files), path("$prefix")     , emit: dataset
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${dataset}"
    """
    nextclade \\
        dataset \\
        get \\
        --name ${dataset} \\
        --tag ${tag} \\
        --output-dir ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        getnextcladedataset: \$(echo \$(nextclade --version 2>&1) | sed 's/^.*nextclade //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    echo $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        getnextcladedataset:  \$(echo \$(nextclade --version 2>&1) | sed 's/^.*nextclade //; s/ .*\$//')
    END_VERSIONS
    """
}
