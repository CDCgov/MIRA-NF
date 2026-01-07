 process GETNEXTCLADEDATASET {
    label 'process_low'

    container 'nextstrain/nextclade:3.18.1'

    input:
    val dataset
    val tag

    output:
    path "$prefix"     , emit: dataset
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
        $args \\
        --name $dataset \\
        $version \\
        --output-dir $prefix

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
