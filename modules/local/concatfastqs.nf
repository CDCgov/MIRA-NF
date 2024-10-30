process CONCATFASTQS {
    tag "${sample}"
    label 'process_single'

    input:
    tuple val(barcode), val(sample), val(file_path)

    output:
    path("${sample}.fastq.gz")

    script:
    def args = task.ext.args ?: ''

    """
    # Concatenate the provided fastq files explicitly
    cat ${file_path}*.fastq* > ${sample}.fastq.gz
    """
}
