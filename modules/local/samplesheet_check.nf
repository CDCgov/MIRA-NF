process SAMPLESHEET_CHECK {
    label 'process_single'

    conda 'conda-forge::python=3.8.3'
    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path samplesheet

    output:
    path '*.csv'       , emit: csv
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in mira/cli/bin/
    """
    check_samplesheet.py \\
        $samplesheet \\
        samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}": python \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
