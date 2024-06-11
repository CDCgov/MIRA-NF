/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FINDCHEMISTRYO       } from "${launchDir}/modules/local/findchemistryo"
include { SUBSAMPLESINGLEREADS } from "${launchDir}/modules/local/subsamplesinglereads"

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

    // Subsample
    new_ch2 = input_ch.map { item ->
        [sample_ID:item.sample, barcodes:item.barcodes, fastq_file_path:item.fastq_1]
    }
    new_ch3 = irma_chemistry_ch.map { item ->
                [sample_ID:item.sample_ID, subsample:item.subsample]
    }
    subsample_ch = new_ch2.combine(new_ch3)
                .filter { it[0].sample_ID == it[1].sample_ID }
                .map { [it[0].sample_ID, it[0].barcodes, it[0].fastq_file_path, it[1].subsample] }
    SUBSAMPLESINGLEREADS(subsample_ch)

    //creating dais module input
    if (params.e == 'Flu-ONT') {
        dais_module = 'INFLUENZA'
    } else if (params.e == 'SC2-Spike-Only-ONT' || 'SC2-Whole-Genome-ONT') {
        dais_module = 'BETACORONAVIRUS'
    }

    emit:
    dais_module         // channel: sample chemistry csv for later
    //irma_ch                   // channel: variables need to run IRMA
    versions = ch_versions    // channel: [ versions.yml ]
}
