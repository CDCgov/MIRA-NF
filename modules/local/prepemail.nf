process PREPEMAIL {
    tag { 'Prepare email for completeion of run' }
    label 'process_single'

    publishDir "${params.outdir}",  mode: 'copy'

    input:
    path('*')
    path(collated_versions)

    output:
    stdout

    script:
    """
    rm ${projectDir}/summary.xlsx
    cp ${params.outdir}/*_summary.xlsx ${projectDir}/summary.xlsx
    cat ${collated_versions} > ${params.outdir}/collated_program_versions.yml
    """
}
