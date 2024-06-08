/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FINDCHEMISTRYI       } from "${launchDir}/modules/local/findchemistryi"
include { SUBSAMPLEPAIREDREADS } from "${launchDir}/modules/local/subsamplepairedreads"

workflow PREPILLUMINAREADS {
    take:
    nf_samplesheet // channel: file path to the nextflowsamplesheet.csv

    main:
    run_ID_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    ch_versions = Channel.empty()

    // Find chemistry
    input_ch = nf_samplesheet
        .splitCsv(header: true)
    new_ch = input_ch.map { item ->
        [item.sample, item.fastq_1]
    }
    find_chemistry_ch = new_ch.combine(run_ID_ch)
    FINDCHEMISTRYI(find_chemistry_ch)
    ch_versions = ch_versions.mix(FINDCHEMISTRYI.out.versions)

    // Create the irma chemistry channel
    irma_chemistry_ch = FINDCHEMISTRYI.out.sample_chem_csv
        .splitCsv(header: true)

    // Subsample
    new_ch2 = input_ch.map { item ->
        [sample:item.sample, fastq_1:item.fastq_1, fastq_2:item.fastq_2]
    }
    new_ch3 = irma_chemistry_ch.map { item ->
                [sample: item.sample_ID, subsample:item.subsample]
    }

    subsample_ch = new_ch2.combine(new_ch3)
                .filter { it[0].sample == it[1].sample }
                .map { [it[0].sample, it[0].fastq_1, it[0].fastq_2, it[1].subsample] }

    SUBSAMPLEPAIREDREADS(subsample_ch)
    fastqs_ch = SUBSAMPLEPAIREDREADS.out.subsampled_fastq

    emit:
    fastqs_ch                 // channel: path to prepared fastq files
    versions = ch_versions    // channel: [ versions.yml ]
}
