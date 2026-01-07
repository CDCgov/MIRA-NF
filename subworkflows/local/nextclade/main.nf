/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NEXTCLADE {

    take:
    summary_ch   // channel: holds aggregate summary report

    main:
    ch_versions = Channel.empty()

    nextclade_ch = summary_ch
    .splitCsv(header: true)
    .map { row ->
        [
        sample_id : row.sample_id,
        reference : row.reference,
        subtype   : row.subtype
        ]
    }

    nextclade_ch.view()

    // TODO nf-core: substitute modules here for the modules of your subworkflow

    emit:
    // TODO nf-core: edit emitted channels

    versions = ch_versions                     // channel: [ versions.yml ]
}
