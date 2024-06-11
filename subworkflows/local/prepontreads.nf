/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FINDCHEMISTRYO       } from "${launchDir}/modules/local/findchemistryo"
include { SUBSAMPLEPAIREDREADS } from "${launchDir}/modules/local/subsamplepairedreads"

workflow PREPONTREADS {
    take:
    nf_samplesheet // channel: file path to the nextflowsamplesheet.csv

    main:
    run_ID_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    dais_module = Channel.empty()
    ch_versions = Channel.empty()

    // Find chemistry
    input_ch = nf_samplesheet
        .splitCsv(header: true)
    new_ch = input_ch.map { item ->
        [item.sample, item.barcodes, item.fastq_1]
    }

    find_chemistry_ch = new_ch.combine(run_ID_ch)
    FINDCHEMISTRYO(find_chemistry_ch)
    ch_versions = ch_versions.unique().mix(FINDCHEMISTRYO.out.versions)

    // Create the irma chemistry channel
    irma_chemistry_ch = FINDCHEMISTRYO.out.sample_chem_csv
        .splitCsv(header: true)

    emit:
    dais_module         // channel: sample chemistry csv for later
    //irma_ch                   // channel: variables need to run IRMA
    versions = ch_versions    // channel: [ versions.yml ]
}
