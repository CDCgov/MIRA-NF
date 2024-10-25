process CONCATFASTQS {
    tag "concat all fastq files within barcode folder ${sample}"
    label 'process_single'

    input:
    tuple val(barcode), val(sample), path(files)   


    output:
    path("${sample}.fastq.gz") 

    script:
    def args = task.ext.args ?: ''

    """
    # Concatenate the provided fastq files explicitly
    cat ${files.join(' ')} > ${sample}.fastq.gz
    """
}