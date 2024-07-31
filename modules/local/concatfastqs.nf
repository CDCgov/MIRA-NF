process CONCATFASTQS {
    tag 'concat all fastq files within barcode folder'
    label 'process_single'

    input:
    tuple val(barcode), val(sample)

    output:
    path('*')

    script:
    def args = task.ext.args ?: ''

    """
    ## Remove folder from any previous runs
    if [ -d -e ${params.runpath}/fastq_pass/cat_fastqs ]; then
    rm -r ${params.runpath}/fastq_pass/cat_fastqs
    fi
    #concat fastq files within barcode folders
    cat ${params.runpath}/fastq_pass/${barcode}/*fastq* > ${sample}.fastq.gz
    """
}
