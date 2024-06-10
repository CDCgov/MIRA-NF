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
    mv *_summary.xlsx summary.xlsx
    cp summary.xlsx ${launchDir}
    """
}
