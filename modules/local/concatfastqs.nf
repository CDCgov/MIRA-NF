process CONCATFASTQS {
    tag "${sample}"
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
    if ls ${params.runpath}/fastq_pass/${barcode}/*fastq* 1> /dev/null 2>&1 ; then
        cat ${params.runpath}/fastq_pass/${barcode}/*fastq* > ${sample}.fastq.gz
    else
        touch ${sample}.fastq
        gzip ${sample}.fastq
    fi
    """
}
