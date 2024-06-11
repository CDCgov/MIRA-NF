/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FINDCHEMISTRYO       } from "${launchDir}/modules/local/findchemistryo"
include { SUBSAMPLESINGLEREADS } from "${launchDir}/modules/local/subsamplesinglereads"
include { TRIMLEFT             } from "${launchDir}/modules/local/trimleft"
include { TRIMRIGHT            } from "${launchDir}/modules/local/trimright"
include { CUTADAPT30           } from "${launchDir}/modules/local/cutadapt30"

workflow PREPONTREADS {
    take:
    nf_samplesheet // channel: file path to the nextflowsamplesheet.csv

    main:
    run_ID_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    barcode_ch = Channel.fromPath('./data/primers/ont_barcodes.csv', checkIfExists: true)
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

    //// Trim reads and adapters
    //left trim
    new_ch4 = SUBSAMPLESINGLEREADS.out.subsampled_fastq.map { item ->
        [sample:item[0], barcode:item[1], subsample_file_path:item[2]]
    }
    set_up_barcode_ch = barcode_ch
        .splitCsv(header: true)
    bc_ch = set_up_barcode_ch.map { item ->
        [barcode:item.barcode, seq_f:item.seq_f, seq_rc:item.seq_rc] }
    trim_ch_l = new_ch4.combine(bc_ch)
        .filter { it[0].barcode == it[1].barcode }
        .map { [it[0].sample, it[0].barcode, it[0].subsample_file_path, it[1].seq_f] }
    TRIMLEFT(trim_ch_l)

    //right trim
    new_ch5 = TRIMLEFT.out.trim_l_fastq.map { item ->
        [sample:item[0], barcode:item[1], trim_l_file_path:item[2]]
    }
    trim_ch_r = new_ch5.combine(bc_ch)
        .filter { it[0].barcode == it[1].barcode }
        .map { [it[0].sample, it[0].barcode, it[0].trim_l_file_path, it[1].seq_rc] }
    TRIMRIGHT(trim_ch_r)

    //cutadapt
    new_ch6 = TRIMRIGHT.out.trim_r_fastq.map { item ->
        [sample:item[0], barcode:item[1], trim_lr_file_path:item[2]]
    }
    CUTADAPT30(new_ch6)

    // Create IRMA channel
    new_ch7 = CUTADAPT30.out.cutadapt_fastq.map { item ->
        [sample_ID: item[0], barcode:item[1], cutadapt_fastq_path:item[2]]
    }
    irma_ch = new_ch7.combine(irma_chemistry_ch)
        .filter { it[0].sample_ID == it[1].sample_ID }
        .map { [it[0].sample_ID, it[0].cutadapt_fastq_path, it[1].irma_custom_0, it[1].irma_custom_1, it[1].irma_module] }

    //creating dais module input
    if (params.e == 'Flu-ONT') {
        dais_module = 'INFLUENZA'
    } else if (params.e == 'SC2-Spike-Only-ONT' || 'SC2-Whole-Genome-ONT') {
        dais_module = 'BETACORONAVIRUS'
    }

    emit:
    dais_module         // channel: sample chemistry csv for later
    irma_ch                   // channel: variables need to run IRMA
    versions = ch_versions    // channel: [ versions.yml ]
}
