process PREPEMAIL {
    tag { 'Prepare email for completeion of run' }
    label 'process_single'
    label 'error_retry'
    publishDir "${params.outdir}",  mode: 'copy'

    input:
    path('*')
    path(collated_versions)

    output:
    stdout

    script:
    """
    rm ${launchDir}/summary.xlsx
    cp ${params.outdir}/*_summary.xlsx ${launchDir}/summary.xlsx
    ## Remove folder if created
    if [ -d ${params.outdir}/prepareirmajson ]; then
    rm -r ${params.outdir}/prepareirmajson
    fi
    cat ${collated_versions} > ${params.outdir}/collated_program_versions.yml
    """
}
