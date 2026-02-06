process SAMPLESHEET_CHECK {
    label 'process_single'

    container 'cdcgov/mira-oxide:v1.4.0'

    input:
    path samplesheet

    output:
    path '*.csv', emit: csv
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // This script is bundled with the pipeline, in mira/cli/bin/
    """
    mira-oxide samplesheet-check -i ${samplesheet} -o samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": mira-oxide \$(mira-oxide --version |& sed '1!d; s/mira-oxide //')
    END_VERSIONS
    """
}
