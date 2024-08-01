process PREPEMAIL {
    tag { 'Prepare email for completeion of run' }
    label 'process_single'

    input:
    path('*')
    path(collated_versions)

    output:
    stdout

    script:
    """
    cp ${params.outdir}/MIRA_*_summary.xlsx ${params.outdir}/email_summary.xlsx
    cat ${collated_versions} > ${params.outdir}/collated_program_versions.yml
    """
}
