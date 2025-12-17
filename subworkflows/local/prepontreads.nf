/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FINDCHEMISTRY        } from '../../modules/local/findchemistry'
include { SUBSAMPLESINGLEREADS } from '../../modules/local/subsamplesinglereads'
include { TRIMBARCODES         } from '../../modules/local/trimbarcodes'

workflow PREPONTREADS {
    take:
    nf_samplesheet // channel: file path to the nextflowsamplesheet.csv

    main:
    //If sourcepath flag is given, sourcepath will be used for barcode path
    if (params.sourcepath == null) {
        barcode_ch = Channel.fromPath("${projectDir}/data/primers/ont_barcodes.csv", checkIfExists: true)
    } else {
        barcode_ch = Channel.fromPath("${params.sourcepath}/data/primers/ont_barcodes.csv", checkIfExists: true)
    }
    dais_module = Channel.empty()
    ch_versions = Channel.empty()

    //if custom irma config used, use custom in irma_module params
    //This will be used in the find_chemistry module
    if (params.custom_irma_config == null) {
        irma_module_ch = params.irma_module
        custom_irma_config_ch = '/none/'
    } else {
        irma_module_ch = 'custom'
        custom_irma_config_ch = params.custom_irma_config
    }

    // Find chemistry
    input_ch = nf_samplesheet
        .splitCsv(header: true)
    new_ch = input_ch.map { item ->
        [item.sample, item.barcodes, item.fastq_1]
    }

    find_chemistry_ch = input_ch.map { item ->
        [item.sample, item.fastq_1]
    }
    FINDCHEMISTRY(find_chemistry_ch, params.subsample_reads, irma_module_ch, custom_irma_config_ch)
    ch_versions = ch_versions.unique().mix(FINDCHEMISTRY.out.versions)

    // Create the irma chemistry channel
    irma_chemistry_ch = FINDCHEMISTRY.out.sample_chem_csv
        .splitCsv(header: true)

    // Subsample
    if (params.subsample_reads > 0) {
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

        subsample_output_ch = SUBSAMPLESINGLEREADS.out.subsampled_fastq
        subsample_output_ch
    } else {
        subsample_output_ch = new_ch
    }

    //// Trim Barcodes
    new_ch4 = subsample_output_ch.map { item ->
        [sample:item[0], barcode:item[1], subsample_file_path:item[2]]
    }
    set_up_barcode_ch = barcode_ch
        .splitCsv(header: true)
    bc_ch = set_up_barcode_ch.map { item ->
        [barcode:item.barcode, seq:item.seq_f] }
    trim_ch = new_ch4.combine(bc_ch)
        .filter { it[0].barcode == it[1].barcode }
        .map { [it[0].sample, it[0].barcode, it[0].subsample_file_path, it[1].seq] }
    TRIMBARCODES(trim_ch)
    ch_versions = ch_versions.unique().mix(TRIMBARCODES.out.versions)

    // Create IRMA channel
    new_ch5 = TRIMBARCODES.out.bartrim_fastq.map { item ->
        [sample_ID: item[0], barcode:item[1], bartrim_fastq_path:item[2]]
    }
    irma_ch = new_ch5.combine(irma_chemistry_ch)
        .filter { it[0].sample_ID == it[1].sample_ID }
        .map { [it[0].sample_ID, it[0].bartrim_fastq_path, it[1].irma_custom, it[1].irma_module] }

    //creating dais module input
    if (params.e == 'Flu-ONT') {
        dais_module = 'INFLUENZA'
    } else if (params.e == 'SC2-Spike-Only-ONT') {
        dais_module = 'BETACORONAVIRUS'
    } else if (params.e == 'SC2-Whole-Genome-ONT') {
        dais_module = 'BETACORONAVIRUS'
    }  else if (params.e == 'RSV-ONT') {
        dais_module = 'RSV'
    }

    emit:
    dais_module         // channel: sample chemistry csv for later
    irma_ch                   // channel: variables need to run IRMA
    versions = ch_versions    // channel: [ versions.yml ]
}
