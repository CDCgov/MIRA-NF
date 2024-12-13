process CHECKMIRAVERSION {
    label 'process_single'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path description_file_path

    output:
    stdout

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    wget -O DESCRIPTION https://raw.githubusercontent.com/CDCgov/MIRA-NF/refs/heads/master/DESCRIPTION
    python ${projectDir}/bin/checkmiraversion.py -g ./DESCRIPTION -l ${description_file_path}

    """
}
