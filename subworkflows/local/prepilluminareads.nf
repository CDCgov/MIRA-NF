/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FINDCHEMISTRYI       } from "${launchDir}/modules/local/findchemistryi"
include { SUBSAMPLEPAIREDREADS } from "${launchDir}/modules/local/subsamplepairedreads"
include { TRIMPRIMERSLEFT      } from "${launchDir}/modules/local/trimprimersleft"
include { TRIMPRIMERSRIGHT     } from "${launchDir}/modules/local/trimprimersright"

workflow PREPILLUMINAREADS {
    take:
    nf_samplesheet // channel: file path to the nextflowsamplesheet.csv

    main:
    run_ID_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    primers = Channel.fromPath('./data/primers/', checkIfExists: true)
    dais_module = Channel.empty()
    ch_versions = Channel.empty()

    //if primers given,set the file path to them
    if (params.p) {
        if (params.p == 'artic3') {
            primers = Channel.fromPath('./data/primers/articv3.fasta', checkIfExists: true)
        } else if (params.p == 'atric4') {
            primers = Channel.fromPath('./data/primers/articv4.fasta', checkIfExists: true)
        } else if (params.p == 'atric4.1') {
            primers = Channel.fromPath('./data/primers/articv4.1.fasta', checkIfExists: true)
        } else if (params.p == 'atric5.3.2') {
            primers = Channel.fromPath('./data/primers/articv5.3.2.fasta', checkIfExists: true)
        } else if (params.p == 'qiagen') {
            primers = Channel.fromPath('./data/primers/QIAseqDIRECTSARSCoV2primersfinal.fasta', checkIfExists: true)
        } else if (params.p == 'swift') {
            primers = Channel.fromPath('./data/primers/SNAP_v2_amplicon_panel.fasta', checkIfExists: true)
        } else if (params.p == 'swift_211206') {
            primers = Channel.fromPath('./data/primers/swift_211206.fasta', checkIfExists: true)
        }  else if (params.p == 'varskip') {
            primers = Channel.fromPath('./data/primers/neb_vss1a.primer.fasta', checkIfExists: true)
        }
    } else {
        primers = Channel.fromPath('./data/primers/', checkIfExists: true)
    }

    // Find chemistry
    input_ch = nf_samplesheet
        .splitCsv(header: true)
    new_ch = input_ch.map { item ->
        [item.sample, item.fastq_1]
    }
    find_chemistry_ch = new_ch.combine(run_ID_ch)
    FINDCHEMISTRYI(find_chemistry_ch)
    ch_versions = ch_versions.unique().mix(FINDCHEMISTRYI.out.versions)

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

    new_ch4 = new_ch2.combine(new_ch3)
        .filter { it[0].sample == it[1].sample }
        .map { [it[0].sample, it[0].fastq_1, it[0].fastq_2, it[1].subsample] }

    subsample_ch = new_ch4.combine(primers)

    SUBSAMPLEPAIREDREADS(subsample_ch)
    ch_versions = ch_versions.unique().mix(SUBSAMPLEPAIREDREADS.out.versions)

    //If primer are given then the reads will go through a trimming step.
    //If not they are passed to the irma channel immediately
    if (params.p) {
        //// Trim primers
        //left trim
        TRIMPRIMERSLEFT(SUBSAMPLEPAIREDREADS.out.subsampled_fastq)
        ch_versions = ch_versions.mix(TRIMPRIMERSLEFT.out.versions)
        //right trim
        TRIMPRIMERSRIGHT(TRIMPRIMERSLEFT.out.trim_l_fastqs)
        ch_versions = ch_versions.mix(TRIMPRIMERSRIGHT.out.versions)

        //// Make IRMA input channel without trimming primers
        //restructing read 1 and read2 so that they are passed as one thing - this is for the IRMA module fastq input
        read_1_ch = TRIMPRIMERSRIGHT.out.trim_lr_fastqs.map { item ->
            [ item[0], item[1]]
        }
        read_2_ch = TRIMPRIMERSRIGHT.out.trim_lr_fastqs.map { item ->
            [item[0], item[2]]
        }
        reads_ch = read_1_ch.concat(read_2_ch)
        reads_combined_ch = reads_ch.groupTuple(by: 0)
        reads_combined_ch.map { item ->
            [ sample_ID: item[0], subsampled_fastq_files: item[1]]
        }
        .set { final_combined_reads_ch }

        //combining chemistry info with read info
        irma_ch = final_combined_reads_ch.combine(irma_chemistry_ch)
        .filter { it[0].sample_ID == it[1].sample_ID }
        .map { [it[0].sample_ID, it[0].subsampled_fastq_files, it[1].irma_custom_0, it[1].irma_custom_1, it[1].irma_module] }
    } else {
        //// Make IRMA input channel without trimming primers
        //restructing read 1 and read2 so that they are passed as one thing - this is for the IRMA module fastq input
        read_1_ch = SUBSAMPLEPAIREDREADS.out.subsampled_fastq.map { item ->
            [ item[0], item[1]]
        }
        read_2_ch = SUBSAMPLEPAIREDREADS.out.subsampled_fastq.map { item ->
            [item[0], item[2]]
        }
        reads_ch = read_1_ch.concat(read_2_ch)
        reads_combined_ch = reads_ch.groupTuple(by: 0)
        reads_combined_ch.map { item ->
            [ sample_ID: item[0], subsampled_fastq_files: item[1]]
        }
        .set { final_combined_reads_ch }

        //combining chemistry info with read info
        irma_ch = final_combined_reads_ch.combine(irma_chemistry_ch)
        .filter { it[0].sample_ID == it[1].sample_ID }
        .map { [it[0].sample_ID, it[0].subsampled_fastq_files, it[1].irma_custom_0, it[1].irma_custom_1, it[1].irma_module] }
    }

    //creating dais module input
    if (params.e == 'Flu_Illumina') {
        dais_module = 'INFLUENZA'
    } else if (params.e == 'SC2-Whole-Genome-Illumina') {
        dais_module = 'BETACORONAVIRUS'
    }

    emit:
    dais_module         // channel: sample chemistry csv for later
    irma_ch                   // channel: variables need to run IRMA
    versions = ch_versions    // channel: [ versions.yml ]
}
