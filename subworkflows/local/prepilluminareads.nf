/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FINDCHEMISTRYI       } from '../../modules/local/findchemistryi'
include { SUBSAMPLEPAIREDREADS } from '../../modules/local/subsamplepairedreads'
include { FLUTRIMPRIMERS       } from '../../modules/local/flutrimprimers'
include { SC2TRIMPRIMERS       } from '../../modules/local/sc2trimprimers'
include { RSVTRIMPRIMERS       } from '../../modules/local/rsvtrimprimers'

workflow PREPILLUMINAREADS {
    take:
    nf_samplesheet // channel: file path to the nextflowsamplesheet.csv

    main:
    run_ID_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    dais_module = Channel.empty()
    ch_versions = Channel.empty()
    primer_kmer_len = Channel.value(params.primer_kmer_len)
    primer_restrict_window = Channel.value(params.primer_restrict_window)
    //If sourcepath flag is given, sourcepath will be used for the file path to the primers
    if (params.sourcepath == null) {
        primer_path = Channel.fromPath("${projectDir}/data/primers/", checkIfExists: true)
        primers = Channel.fromPath("${projectDir}/data/primers/", checkIfExists: true)
        if (params.p) {
            if (params.p == 'artic3') {
                primers = Channel.fromPath("${projectDir}/data/primers/articv3.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of('21')
                primer_restrict_window = Channel.of(40) 
            } else if (params.p == 'artic4') {
                primers = Channel.fromPath("${projectDir}/data/primers/articv4.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of(19)
                primer_restrict_window = Channel.of(40)
            } else if (params.p == 'artic4.1') {
                primers = Channel.fromPath("${projectDir}/data/primers/articv4.1.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of(20)
                primer_restrict_window = Channel.of(40)
            } else if (params.p == 'artic5.3.2') {
                primers = Channel.fromPath("${projectDir}/data/primers/articv5.3.2.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of(19)
                primer_restrict_window = Channel.of(40) 
            } else if (params.p == 'qiagen') {
                primers = Channel.fromPath("${projectDir}/data/primers/QIAseqDIRECTSARSCoV2primersfinal.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of(19)
                primer_restrict_window = Channel.of(40)
            } else if (params.p == 'swift') {
                primers = Channel.fromPath("${projectDir}/data/primers/SNAP_v2_amplicon_panel.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of(17)
                primer_restrict_window = Channel.of(40)
            } else if (params.p == 'swift_211206') {
                primers = Channel.fromPath("${projectDir}/data/primers/swift_211206.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of(17)
                primer_restrict_window = Channel.of(40) 
            }  else if (params.p == 'varskip') {
                primers = Channel.fromPath("${projectDir}/data/primers/neb_vss1a.primer.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of(19)
                primer_restrict_window = Channel.of(40)
            }  else if (params.p == 'RSV_CDC_8amplicon_230901') {
                primers = Channel.fromPath("${projectDir}/data/primers/RSV_CDC_8amplicon_230901.fasta", checkIfExists: true)
                primer_kmer_len = Channel.of(19)
                primer_restrict_window = Channel.of(40)
            }
        }
    } else {
        primer_path = Channel.fromPath("${params.sourcepath}/data/primers/", checkIfExists: true)
        primers = Channel.fromPath("${params.sourcepath}/data/primers/", checkIfExists: true)
        if (params.p) {
            if (params.p == 'artic3') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/articv3.fasta", checkIfExists: true)
                primer_kmer_len = '21'
                primer_restrict_window = '40'
            } else if (params.p == 'artic4') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/articv4.fasta", checkIfExists: true)
                primer_kmer_len = '19'
                primer_restrict_window = '40'
            } else if (params.p == 'artic4.1') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/articv4.1.fasta", checkIfExists: true)
                primer_kmer_len = '20'
                primer_restrict_window = '40'
            } else if (params.p == 'artic5.3.2') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/articv5.3.2.fasta", checkIfExists: true)
                primer_kmer_len = '19'
                primer_restrict_window = '40' 
            } else if (params.p == 'qiagen') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/QIAseqDIRECTSARSCoV2primersfinal.fasta", checkIfExists: true)
                primer_kmer_len = '17'
                primer_restrict_window = '40' 
            } else if (params.p == 'swift') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/SNAP_v2_amplicon_panel.fasta", checkIfExists: true)
                primer_kmer_len = '17'
                primer_restrict_window = '40' 
            } else if (params.p == 'swift_211206') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/swift_211206.fasta", checkIfExists: true)
                primer_kmer_len = '17'
                primer_restrict_window = '40' 
            }  else if (params.p == 'varskip') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/neb_vss1a.primer.fasta", checkIfExists: true)
                primer_kmer_len = '19'
                primer_restrict_window = '40' 
            }  else if (params.p == 'RSV_CDC_8amplicon_230901') {
                primers = Channel.fromPath("${params.sourcepath}/data/primers/RSV_CDC_8amplicon_230901.fasta", checkIfExists: true)
                primer_kmer_len = '19'
                primer_restrict_window = '40' 
            }
        }
    }

    // if primers given, set the file path to them
    if (params.custom_primers) {
        primers = Channel.fromPath("${params.custom_primers}", checkIfExists: true)
    }

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
    find_chemistry_ch = input_ch.map { item ->
        [item.sample, item.fastq_1]
    }
    FINDCHEMISTRYI(find_chemistry_ch, params.subsample_reads, irma_module_ch, custom_irma_config_ch)
    ch_versions = ch_versions.unique().mix(FINDCHEMISTRYI.out.versions)

    // Create the irma chemistry channel
    irma_chemistry_ch = FINDCHEMISTRYI.out.sample_chem_csv
        .splitCsv(header: true)
        .filter { it.size() > 0 }

    sample_empty_fastq_ch = FINDCHEMISTRYI.out.sample_chem_csv
        .splitCsv(header: true)
        .filter { it.size() == 0 }

    // Subsample
    if (params.subsample_reads > 0) {
        new_ch2 = input_ch.map { item ->
            [sample:item.sample, fastq_1:item.fastq_1, fastq_2:item.fastq_2]
        }
        new_ch3 = irma_chemistry_ch.map { item ->
            [sample: item.sample_ID, subsample:item.subsample]
        }

        new_ch4 = new_ch2.combine(new_ch3)
            .filter { it[0].sample == it[1].sample }
            .map { [it[0].sample, it[0].fastq_1, it[0].fastq_2, it[1].subsample] }

        subsample_ch = new_ch4.combine(primers).combine(primer_kmer_len).combine(primer_restrict_window)

        SUBSAMPLEPAIREDREADS(subsample_ch)
        ch_versions = ch_versions.unique().mix(SUBSAMPLEPAIREDREADS.out.versions)

        subsample_output_ch = SUBSAMPLEPAIREDREADS.out.subsampled_fastq
        } else {
            new_ch2 = input_ch.map { item ->
                [sample:item.sample, fastq_1:item.fastq_1, fastq_2:item.fastq_2]
            }

            new_ch3 = new_ch2.combine(primers)
            .map { [it[0].sample, it[0].fastq_1, it[0].fastq_2, it[1]] }

            subsample_output_ch = new_ch3.combine(primer_kmer_len).combine(primer_restrict_window)
    }

    // If experiment type is SC2-Whole-Genome-Illumina then samples will go through the primer trimming steps with SC2 primers
    // If not they are passed to the irma channel immediately
    if (params.e == 'SC2-Whole-Genome-Illumina') {
        //// Trim primers
        //primer trim
        SC2TRIMPRIMERS(subsample_output_ch)
        ch_versions = ch_versions.mix(SC2TRIMPRIMERS.out.versions)

        //// Make IRMA input channel without trimming primers
        // restructing read 1 and read2 so that they are passed as one thing - this is for the IRMA module fastq input
        read_1_ch = SC2TRIMPRIMERS.out.trim_fastqs.map { item ->
            [ item[0], item[1]]
        }
        read_2_ch = SC2TRIMPRIMERS.out.trim_fastqs.map { item ->
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
    } else if (params.e == 'RSV-Illumina') {
        //// Trim primers
        RSVTRIMPRIMERS(subsample_output_ch)
        ch_versions = ch_versions.mix(RSVTRIMPRIMERS.out.versions)

        //// Make IRMA input channel without trimming primers
        // restructing read 1 and read2 so that they are passed as one thing - this is for the IRMA module fastq input
        read_1_ch = RSVTRIMPRIMERS.out.trim_fastqs.map { item ->
            [ item[0], item[1]]
        }
        read_2_ch = RSVTRIMPRIMERS.out.trim_fastqs.map { item ->
            [item[0], item[2]]
        }
        reads_ch = read_1_ch.concat(read_2_ch)
        reads_combined_ch = reads_ch.groupTuple(by: 0)
        reads_combined_ch.map { item ->
            [ sample_ID: item[0], subsampled_fastq_files: item[1]]
        }
        .set { final_combined_reads_ch }

        // combining chemistry info with read info
        irma_ch = final_combined_reads_ch.combine(irma_chemistry_ch)
        .filter { it[0].sample_ID == it[1].sample_ID }
        .map { [it[0].sample_ID, it[0].subsampled_fastq_files, it[1].irma_custom_0, it[1].irma_custom_1, it[1].irma_module] }
    } else if (params.e == 'Flu-Illumina' && params.custom_primers != null) {
        //// Trim reads with custom flu primers
        FLUTRIMPRIMERS(subsample_output_ch)
        ch_versions = ch_versions.mix(FLUTRIMPRIMERS.out.versions)

        // restructing read 1 and read2 so that they are passed as one thing - this is for the IRMA module fastq input
        read_1_ch = FLUTRIMPRIMERS.out.trim_fastqs.map { item ->
            [ item[0], item[1]]
        }
        read_2_ch = FLUTRIMPRIMERS.out.trim_fastqs.map { item ->
            [item[0], item[2]]
        }
        reads_ch = read_1_ch.concat(read_2_ch)
        reads_combined_ch = reads_ch.groupTuple(by: 0)
        reads_combined_ch.map { item ->
            [ sample_ID: item[0], subsampled_fastq_files: item[1]]
        }
        .set { final_combined_reads_ch }

        // combining chemistry info with read info
        irma_ch = final_combined_reads_ch.combine(irma_chemistry_ch)
        .filter { it[0].sample_ID == it[1].sample_ID
         }
        .map { [it[0].sample_ID, it[0].subsampled_fastq_files, it[1].irma_custom_0, it[1].irma_custom_1, it[1].irma_module] }
    } else if (params.e == 'Flu-Illumina' && params.custom_primers == null) {
        //// Make IRMA input channel without trimming primers
        // restructing read 1 and read2 so that they are passed as one thing - this is for the IRMA module fastq input
        read_1_ch = subsample_output_ch.map { item ->
            [ item[0], item[1]]
        }
        read_2_ch = subsample_output_ch.map { item ->
            [item[0], item[2]]
        }
        reads_ch = read_1_ch.concat(read_2_ch)
        reads_combined_ch = reads_ch.groupTuple(by: 0)
        reads_combined_ch.map { item ->
            [ sample_ID: item[0], subsampled_fastq_files: item[1]]
        }
        .set { final_combined_reads_ch }

        // combining chemistry info with read info
        irma_ch = final_combined_reads_ch.combine(irma_chemistry_ch)
        .filter { it[0].sample_ID == it[1].sample_ID }
        .map { [it[0].sample_ID, it[0].subsampled_fastq_files, it[1].irma_custom_0, it[1].irma_custom_1, it[1].irma_module] }
    }

    // creating dais module input
    if (params.e == 'Flu-Illumina') {
        dais_module = 'INFLUENZA'
    } else if (params.e == 'SC2-Whole-Genome-Illumina') {
        dais_module = 'BETACORONAVIRUS'
    } else if (params.e == 'RSV-Illumina') {
        dais_module = 'RSV'
    }

    emit:
    dais_module         // channel: sample chemistry csv for later
    irma_ch                   // channel: variables need to run IRMA
    versions = ch_versions    // channel: [ versions.yml ]
}
