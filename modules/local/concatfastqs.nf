process CONCATFASTQS {
    tag 'concat all fastq files within barcode folder'

    publishDir "${params.outdir}/fastq_pass/cat_fastqs", mode: 'copy'

    input:
    tuple val(barcode), val(sample)

    output:
    path('*')

    script:
    def args = task.ext.args ?: ''

    """
    #Removing if previous made
    if [ -f -e ${launchDir}/summary.xlsx ]; then
    rm ${launchDir}/summary.xlsx
    fi
    #Set up so that email sends whether workflow finishes or not
    cp ${launchDir}/assets/summary.xlsx ${launchDir}/summary.xlsx
    ## Remove folder from any previous runs
    if [ -d -e ${params.outdir}/fastq_pass/cat_fastqs ]; then
    rm -r ${params.outdir}/fastq_pass/cat_fastqs
    fi
    #concat fastq files within barcode folders
    cat ${params.outdir}/fastq_pass/${barcode}/*fastq* > ${sample}.fastq.gz
    """
}
