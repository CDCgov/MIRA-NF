process CONCATFASTQS {
    tag 'concat all fastq files within barcode folder'
    label 'process_single'

    publishDir "${params.outdir}/fastq_pass/cat_fastqs", mode: 'copy'

    input:
    tuple val(barcode), val(sample)

    output:
    path('*')

    script:
    def args = task.ext.args ?: ''

    """
    #Removing if previous made
    if [ -f -e ${projectDir}/summary.xlsx ]; then
    rm ${projectDir}/summary.xlsx
    fi
    #Set up so that email sends whether workflow finishes or not
    cp ${projectDir}/assets/summary.xlsx ${projectDir}/summary.xlsx
    ## Remove folder from any previous runs
    if [ -d -e ${params.runpath}/fastq_pass/cat_fastqs ]; then
    rm -r ${params.runpath}/fastq_pass/cat_fastqs
    fi
    #concat fastq files within barcode folders
    cat ${params.runpath}/fastq_pass/${barcode}/*fastq* > ${sample}.fastq.gz
    """
}
