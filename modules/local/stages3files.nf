process STAGES3FILES {
    label 'stage_s3_files'

    input:
    val runid
    val folder
    path fastq_file, stageAs: '?/*'

    output:
    val "${folder}"

    script:
    """
    echo "Staging file to ./${folder}"
    if [ -d -e ./${folder}]; then
    rm -r ./${folder}
    fi
    mkdir -p ./${folder}
    cp ${fastq_file} ./${folder}
    """
}
