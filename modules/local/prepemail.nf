process PREPEMAIL {
    tag { 'Prepare email for completeion of run' }

    publishDir "${params.outdir}",  mode: 'copy'

    input:
    path('*')

    output:
    stdout

    script:
    """
    rm ${launchDir}/summary.xlsx
    cp ${params.outdir}/*_summary.xlsx ${launchDir}/summary.xlsx
    ## Remove folder if created
    if [ -d -e ${params.outdir}/prepareirmajson ]; then
    rm -r ${params.outdir}/prepareirmajson
    fi
    """
}
