/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { STAGES3FILES        } from '../modules/local/stages3files'
include { CONCATFASTQS         } from '../modules/local/concatfastqs'
include { NEXTFLOWSAMPLESHEETI } from '../modules/local/nextflowsamplesheeti'
include { NEXTFLOWSAMPLESHEETO } from '../modules/local/nextflowsamplesheeto'
include { INPUT_CHECK          } from '../subworkflows/local/input_check'
include { READQC               } from '../subworkflows/local/readqc'
include { PREPILLUMINAREADS    } from '../subworkflows/local/prepilluminareads'
include { PREPONTREADS         } from '../subworkflows/local/prepontreads'
include { IRMA                 } from '../modules/local/irma'
include { CHECKIRMA            } from '../subworkflows/local/checkirma'
include { DAISRIBOSOME         } from '../modules/local/daisribosome'
include { VARIANTSOFINT        } from '../modules/local/variantsofint'
include { POSITIONSOFINT       } from '../modules/local/positionsofint'
include { PREPAREREPORTS       } from '../subworkflows/local/preparereports'
include { CHECKMIRAVERSION     } from '../modules/local/checkmiraversion'
include { NEXTCLADE            } from '../subworkflows/local/nextclade'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// input is the sample sheet
// outdir is the run directory

workflow flu_i {
    // Error handling to prevent incorrect flags being used
    //check for runpath
    if (params.runpath == null) {
    println 'ERROR!!: Aborting pipeline due missing runpath flags'
    println 'Please provide the file path to the run folder using the runpath flag'
    workflow.exit
    }
    // irma config handling
    if (params.irma_module != 'none' && params.custom_irma_config != null) {
        println 'ERROR!!: Aborting pipeline due to conflicting flags'
        println 'Please provide either the --irma_module or --custom_irma_config flag.'
        println 'They cannot be used together.'
        workflow.exit
    }
    // primer error handling
    if (params.custom_primers != null && (params.primer_kmer_len == null || params.primer_restrict_window == null)) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'custom_primers flag requires primer_kmer_len and primer_restrict_window flags be specified as well.'
        workflow.exit()
    }

    if (params.p != null && params.custom_primers == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. Flu-Illumina experiment type does not have default primer trimming.'
        println 'Please remove --p to continue.'
        workflow.exit
    }
    if (params.p != null && params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. Flu-Illumina experiment type does not have built in primer sets.'
        println 'Please remove flags --p to continue.'
        workflow.exit
    }
    //error handling for variants_of_interest and positions_of_interest flag
    if (params.variants_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The variants_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The positions_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.variants_of_interest == null && params.positions_of_interest == null && params.reference_seq_table != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The reference_seq_table flag is only used when the variants_of_interest or postions_of_interest is used.'
        println 'Please provide a table of variants with the variants_of_interest or the postions_of_interest flag'
        workflow.exit
    }
    if (params.dais_module != null) {
        println 'ERROR!!: The dais_module flag only needs to be specificied with the Find-Variants-Of-Interest or Find-Positions-Of-Interest workflow.'
        workflow.exit
    }

    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()
    if (params.custom_runid != null) {
        runid = params.custom_runid
    } else {
        def path = "${params.runpath}"
        def folder_name = new File(path)
        runid = folder_name.name
    }

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow
        // Stage fastq files based on profile
        if (params.restage == true){
            fastq_ch = Channel
                .fromPath("${params.runpath}/**/*.fastq.gz", checkIfExists: true)
                .collect()
            sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)
        } else if (params.restage == false ){
            sequences_ch = Channel.fromPath("${params.runpath}/fastqs", checkIfExists: true)

        }

        NEXTFLOWSAMPLESHEETI(samplesheet_ch, sequences_ch, experiment_type_ch)
        // OMICS & Local PLATFORM: END

        ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETI.out.versions)
        nf_samplesheet_ch = NEXTFLOWSAMPLESHEETI.out.nf_samplesheet

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    } else if (params.amd_platform == true) {
        //save samplesheet as the nf sample
        nf_samplesheet_ch = samplesheet_ch

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(nf_samplesheet_ch)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    }

    // Run or pass READQC subworkflow based on read_qc parameter
    if (params.read_qc == false) {
        println 'Bypassing FastQC and MultiQC steps'
    } else if (params.read_qc == true) {
        // SUBWORKFLOW: Process reads through FastQC and MultiQC
        READQC(INPUT_CHECK.out.reads)
        ch_versions = ch_versions.unique().mix(READQC.out.versions)
    }

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPILLUMINAREADS(nf_samplesheet_ch)
    ch_versions = ch_versions.unique().mix(PREPILLUMINAREADS.out.versions)

    // MODULE: Run IRMA
    IRMA(PREPILLUMINAREADS.out.irma_ch)
    ch_versions = ch_versions.unique().mix(IRMA.out.versions)

    // SUBWORKFLOW: Check IRMA outputs and prepare passed and failed samples
    check_irma_ch = IRMA.out.outputs.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CHECKIRMA(check_irma_ch)

    // MODULE: Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPILLUMINAREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Variants of Interest
    if(params.variants_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        variant_of_int_table_ch = Channel.fromPath(params.variants_of_interest, checkIfExists: true)
        VARIANTSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, variant_of_int_table_ch)
    }

    //MODULE: Run Positions of Interest
    if(params.positions_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        positions_of_int_table_ch = Channel.fromPath(params.positions_of_interest, checkIfExists: true)
        POSITIONSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, positions_of_int_table_ch)
    }

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )

    // SUBWORKFLOW: Run Nextclade
    if(params.nextclade){
        NEXTCLADE(PREPAREREPORTS.out.summary_ch)
    }
}

workflow flu_o {
    // Error handling to prevent incorrect flags being used
    //check for runpath
    if (params.runpath == null) {
    println 'ERROR!!: Aborting pipeline due missing runpath flags'
    println 'Please provide the file path to the run folder using the runpath flag'
    workflow.exit
    }
    // irma config handling
    if (params.irma_module != 'none' && params.custom_irma_config != null) {
        println 'ERROR!!: Aborting pipeline due to conflicting flags'
        println 'Please provide only the --custom_irma_config flag.'
        println 'Currently, the --irma_module flag is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    if (params.irma_module != 'none') {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'Currently, the --irma_module is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    // primer error handling
    if (params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. Flu-ONT experiment type does not need primers.'
        println 'Please remove --custom_primers to continue.'
        workflow.exit
    } else if (params.p != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. Flu-ONT experiment type does not need primers.'
        println 'Please remove --p to continue.'
        workflow.exit
    }
    if (params.p != null && params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. Flu-ONT experiment type does not need primers.'
        println 'Please remove flags --p and --custom_primers to continue.'
        workflow.exit
    }
    //error handling for variants_of_interest and positions_of_interest flag
    if (params.variants_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The variants_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The positions_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.variants_of_interest == null && params.positions_of_interest == null && params.reference_seq_table != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The reference_seq_table flag is only used when the variants_of_interest or postions_of_interest is used.'
        println 'Please provide a table of variants with the variants_of_interest or the postions_of_interest flag'
        workflow.exit
    }
    if (params.dais_module != null) {
        println 'ERROR!!: The dais_module flag only needs to be specificied with the Find-Variants-Of-Interest or Find-Positions-Of-Interest workflow.'
        workflow.exit
    }

    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // MODULE: Concat all fastq files by barcode
        // Prepare new_ch with tuples
        set_up_ch = samplesheet_ch
            .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
        fastq_ch = set_up_ch.map { item ->
            def barcode = item.barcode
            def sample_id = item.sample_id
            def fastq_path = "${params.runpath}/fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, collected_concatenated_fastqs_ch, experiment_type_ch)
        // OMICS & Local END

        ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETO.out.versions)
        nf_samplesheet_ch = NEXTFLOWSAMPLESHEETO.out.nf_samplesheet

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    } else if (params.amd_platform == true) {
        //save samplesheet as the nf sample
        nf_samplesheet_ch = samplesheet_ch

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(nf_samplesheet_ch)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    }

    // Run or pass READQC subworkflow based on read_qc parameter
    if (params.read_qc == false) {
        println 'Bypassing FastQC and MultiQC steps'
    } else if (params.read_qc == true) {
        // SUBWORKFLOW: Process reads through FastQC and MultiQC
        READQC(INPUT_CHECK.out.reads)
        ch_versions = ch_versions.unique().mix(READQC.out.versions)
    }

    // SUBWORKFLOW: Process ONT reads for IRMA - find chemistry and subsample
    PREPONTREADS(nf_samplesheet_ch)
    ch_versions = ch_versions.unique().mix(PREPONTREADS.out.versions)

    // MODULE: Run IRMA
    IRMA(PREPONTREADS.out.irma_ch)
    ch_versions = ch_versions.unique().mix(IRMA.out.versions)

    // SUBWORKFLOW: Check IRMA outputs and prepare passed and failed samples
    check_irma_ch = IRMA.out.outputs.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CHECKIRMA(check_irma_ch)

    // MODULE: Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Variants of Interest
    if(params.variants_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        variant_of_int_table_ch = Channel.fromPath(params.variants_of_interest, checkIfExists: true)
        VARIANTSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, variant_of_int_table_ch)
    }

    //MODULE: Run Positions of Interest
    if(params.positions_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        positions_of_int_table_ch = Channel.fromPath(params.positions_of_interest, checkIfExists: true)
        POSITIONSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, positions_of_int_table_ch)
    }

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )
}

workflow sc2_spike_o {
    // Error handling to prevent incorrect flags being used
    //check for runpath
    if (params.runpath == null) {
    println 'ERROR!!: Aborting pipeline due missing runpath flags'
    println 'Please provide the file path to the run folder using the runpath flag'
    workflow.exit
    }
    // irma config handling
    if (params.irma_module != 'none' && params.custom_irma_config != null) {
        println 'ERROR!!: Aborting pipeline due to conflicting flags'
        println 'Please provide only the --custom_irma_config flag.'
        println 'Currently, the --irma_module flag is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    if (params.irma_module != 'none') {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'Currently, the --irma_module is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    //primer error handling
    if (params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. SC2-Whole-Genome-ONT experiment type does not need primers.'
        println 'Please remove --custom_primers to continue.'
        workflow.exit
    } else if (params.p != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. SC2-Whole-Genome-ONT experiment type does not need primers.'
        println 'Please remove --p to continue.'
        workflow.exit
    }
    if (params.p != null && params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. SC2-Whole-Genome-ONT experiment type does not need primers.'
        println 'Please remove flags --p and --custom_primers to continue.'
        workflow.exit
    }
    //error handling for variants_of_interest and positions_of_interest flag
    if (params.variants_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The variants_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The positions_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.variants_of_interest == null && params.positions_of_interest == null && params.reference_seq_table != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The reference_seq_table flag is only used when the variants_of_interest or postions_of_interest is used.'
        println 'Please provide a table of variants with the variants_of_interest or the postions_of_interest flag'
        workflow.exit
    }
    if (params.dais_module != null) {
        println 'ERROR!!: The dais_module flag only needs to be specificied with the Find-Variants-Of-Interest or Find-Positions-Of-Interest workflow.'
        workflow.exit
    }

    //Inializing parameters
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)

    if (params.amd_platform == false) {
        // OMICS & Local PLATFORM: START Concat all fastq files by barcode
        set_up_ch = samplesheet_ch
            .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
        fastq_ch = set_up_ch.map { item ->
            def barcode = item.barcode
            def sample_id = item.sample_id
            // def fastq_path = "${params.runpath}/**/${barcode}/*.fastq.gz"; // it was not working with **, so I changed it to fastq_pass
            def fastq_path = "${params.runpath}/fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()
        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, collected_concatenated_fastqs_ch, experiment_type_ch)
        // OMICS & Local END

        ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETO.out.versions)
        nf_samplesheet_ch = NEXTFLOWSAMPLESHEETO.out.nf_samplesheet

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    } else if (params.amd_platform == true) {
        //save samplesheet as the nf sample
        nf_samplesheet_ch = samplesheet_ch

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(nf_samplesheet_ch)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    }

    //Run or pass READQC subworkflow based on read_qc parameter
    if (params.read_qc == false) {
        println 'Bypassing FastQC and MultiQC steps'
    } else if (params.read_qc == true) {
        // SUBWORKFLOW: Process reads through FastQC and MultiQC
        READQC(INPUT_CHECK.out.reads)
        ch_versions = ch_versions.unique().mix(READQC.out.versions)
    }

    // SUBWORKFLOW: Process ONT reads for IRMA - find chemistry and subsample
    PREPONTREADS(nf_samplesheet_ch)
    ch_versions = ch_versions.unique().mix(PREPONTREADS.out.versions)

    // Run IRMA
    IRMA(PREPONTREADS.out.irma_ch)
    ch_versions = ch_versions.unique().mix(IRMA.out.versions)

    // SUBWORKFLOW: Check IRMA outputs and prepare passed and failed samples
    check_irma_ch = IRMA.out.outputs.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CHECKIRMA(check_irma_ch)

    // Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Variants of Interest
    if(params.variants_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        variant_of_int_table_ch = Channel.fromPath(params.variants_of_interest, checkIfExists: true)
        VARIANTSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, variant_of_int_table_ch)
    }

    //MODULE: Run Positions of Interest
    if(params.positions_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        positions_of_int_table_ch = Channel.fromPath(params.positions_of_interest, checkIfExists: true)
        POSITIONSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, positions_of_int_table_ch)
    }

    // Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )
}

workflow sc2_wgs_o {
    // Error handling to prevent incorrect flags being used
    //check for runpath
    if (params.runpath == null) {
    println 'ERROR!!: Aborting pipeline due missing runpath flags'
    println 'Please provide the file path to the run folder using the runpath flag'
    workflow.exit
    }
    // irma config handling
    if (params.irma_module != 'none' && params.custom_irma_config != null) {
        println 'ERROR!!: Aborting pipeline due to conflicting flags'
        println 'Please provide only the --custom_irma_config flag.'
        println 'Currently, the --irma_module flag is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    if (params.irma_module != 'none') {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'Currently, the --irma_module is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    //primer error handling
    if (params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. SC2-Spike-Only-ONT experiment type does not need primers.'
        println 'Please remove --custom_primers to continue.'
        workflow.exit
    } else if (params.p != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. SC2-Spike-Only-ONT experiment type does not need primers.'
        println 'Please remove --p to continue.'
        workflow.exit
    }
    if (params.p != null && params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. SC2-Spike-Only-ONT experiment type does not need primers.'
        println 'Please remove flags --p and --custom_primers to continue.'
        workflow.exit
    }
    //error handling for variants_of_interest and positions_of_interest flag
    if (params.variants_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The variants_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The positions_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.variants_of_interest == null && params.positions_of_interest == null && params.reference_seq_table != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The reference_seq_table flag is only used when the variants_of_interest or postions_of_interest is used.'
        println 'Please provide a table of variants with the variants_of_interest or the postions_of_interest flag'
        workflow.exit
    }
    if (params.dais_module != null) {
        println 'ERROR!!: The dais_module flag only needs to be specificied with the Find-Variants-Of-Interest or Find-Positions-Of-Interest workflow.'
        workflow.exit
    }

    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // OMICS & Local PLATFORM: START Concat all fastq files by barcode
        // Prepare new_ch with tuples
        set_up_ch = samplesheet_ch
            .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
        fastq_ch = set_up_ch.map { item ->
            def barcode = item.barcode
            def sample_id = item.sample_id
            def fastq_path = "${params.runpath}/fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, collected_concatenated_fastqs_ch, experiment_type_ch)
        // OMICS & Local END

        ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETO.out.versions)
        nf_samplesheet_ch = NEXTFLOWSAMPLESHEETO.out.nf_samplesheet

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    } else if (params.amd_platform == true) {
        //save samplesheet as the nf sample
        nf_samplesheet_ch = samplesheet_ch

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(nf_samplesheet_ch)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    }

    //Run or pass READQC subworkflow based on read_qc parameter
    if (params.read_qc == false) {
        println 'Bypassing FastQC and MultiQC steps'
    } else if (params.read_qc == true) {
        // SUBWORKFLOW: Process reads through FastQC and MultiQC
        READQC(INPUT_CHECK.out.reads)
        ch_versions = ch_versions.unique().mix(READQC.out.versions)
    }

    // SUBWORKFLOW: Process ONT reads for IRMA - find chemistry and subsample
    PREPONTREADS(nf_samplesheet_ch)
    ch_versions = ch_versions.unique().mix(PREPONTREADS.out.versions)

    // MODULE: Run IRMA
    IRMA(PREPONTREADS.out.irma_ch)
    ch_versions = ch_versions.unique().mix(IRMA.out.versions)

    // SUBWORKFLOW: Check IRMA outputs and prepare passed and failed samples
    check_irma_ch = IRMA.out.outputs.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CHECKIRMA(check_irma_ch)

    // MODULE: Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Variants of Interest
    if(params.variants_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        variant_of_int_table_ch = Channel.fromPath(params.variants_of_interest, checkIfExists: true)
        VARIANTSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, variant_of_int_table_ch)
    }

    //MODULE: Run Positions of Interest
    if(params.positions_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        positions_of_int_table_ch = Channel.fromPath(params.positions_of_interest, checkIfExists: true)
        POSITIONSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, positions_of_int_table_ch)
    }

    //SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)

    //setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )
}

workflow sc2_wgs_i {
    //Error handling to prevent incorrect flags being used
    //check for runpath
    if (params.runpath == null) {
    println 'ERROR!!: Aborting pipeline due missing runpath flags'
    println 'Please provide the file path to the run folder using the runpath flag'
    workflow.exit
    }
    //irma config handling
    if (params.irma_module != 'none' && params.custom_irma_config != null) {
        println 'ERROR!!: Aborting pipeline due to conflicting flags'
        println 'Please provide only the --custom_irma_config flag.'
        println 'Currently, the --irma_module flag is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    if (params.irma_module != 'none') {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'Currently, the --irma_module is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    // primer error handling
    // checking that primer parameter has been provided before proceeding through workflow - aborts pipeline if none are given
    if (params.p == null && params.custom_primers == null) {
        println 'ERROR!!: Aborting pipeline due to missing primer input for trimming'
        println 'Please provide primers using either --p or --custom_primers'
        workflow.exit
    }
    if (params.custom_primers != null && (params.primer_kmer_len == null || params.primer_restrict_window == null)) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'custom_primers flag requires primer_kmer_len and primer_restrict_window flags be specified as well.'
        workflow.exit()
    }
    if (params.p == 'RSV_CDC_8amplicon_230901') {
        println 'ERROR!!: The primer selection provided is not compatible with SARS-CoV-2'
        println 'Please select the one of the SARS-CoV-2 primer sets or provide a custom primer set'
        workflow.exit
    }
    if (params.custom_primers == null && params.p != null) {
        println "using ${params.p} primers for trimming"
    }
    if (params.custom_primers != null && params.p == null) {
        println 'Using custom primers for trimming'
    }
    if (params.p != null && params.custom_primers != null) {
        println 'Both the primer flag and the custom_primer flag have been provided.'
        println 'Using custom primers will be used for trimming'
        params.p = null
    }
    //error handling for variants_of_interest and positions_of_interest flag
    if (params.variants_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The variants_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The positions_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.variants_of_interest == null && params.positions_of_interest == null && params.reference_seq_table != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The reference_seq_table flag is only used when the variants_of_interest or postions_of_interest is used.'
        println 'Please provide a table of variants with the variants_of_interest or the postions_of_interest flag'
        workflow.exit
    }
    if (params.dais_module != null) {
        println 'ERROR!!: The dais_module flag only needs to be specificied with the Find-Variants-Of-Interest or Find-Positions-Of-Interest workflow.'
        workflow.exit
    }


    //Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()
    if (params.custom_runid != null) {
        runid = params.custom_runid
    } else {
        def path = "${params.runpath}"
        def folder_name = new File(path)
        runid = folder_name.name
    }

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow format
        // Stage fastq files based on profile
        if (params.restage == true){
            fastq_ch = Channel
                .fromPath("${params.runpath}/**/*.fastq.gz", checkIfExists: true)
                .collect()
            sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)
        } else if (params.restage == false ){
            sequences_ch = Channel.fromPath("${params.runpath}/fastqs", checkIfExists: true)
        }

        NEXTFLOWSAMPLESHEETI(samplesheet_ch, sequences_ch, experiment_type_ch)
        // OMICS & Local PLATFORM: END

        // NEXTFLOWSAMPLESHEETI(samplesheet_ch, experiment_type_ch)
        ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETI.out.versions)
        nf_samplesheet_ch = NEXTFLOWSAMPLESHEETI.out.nf_samplesheet

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    } else if (params.amd_platform == true) {
        // save samplesheet as the nf sample
        nf_samplesheet_ch = samplesheet_ch

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(nf_samplesheet_ch)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    }

    // Run or pass READQC subworkflow based on read_qc parameter
    if (params.read_qc == false) {
        println 'Bypassing FastQC and MultiQC steps'
    } else if (params.read_qc == true) {
        // SUBWORKFLOW: Process reads through FastQC and MultiQC
        READQC(INPUT_CHECK.out.reads)
        ch_versions = ch_versions.unique().mix(READQC.out.versions)
    }

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPILLUMINAREADS(nf_samplesheet_ch)
    ch_versions = ch_versions.unique().mix(PREPILLUMINAREADS.out.versions)

    // MODULE: Run IRMA
    IRMA(PREPILLUMINAREADS.out.irma_ch)
    ch_versions = ch_versions.unique().mix(IRMA.out.versions)

    // SUBWORKFLOW: Check IRMA outputs and prepare passed and failed samples
    check_irma_ch = IRMA.out.outputs.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CHECKIRMA(check_irma_ch)

    // MODULE: Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPILLUMINAREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Variants of Interest
    if(params.variants_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        variant_of_int_table_ch = Channel.fromPath(params.variants_of_interest, checkIfExists: true)
        VARIANTSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, variant_of_int_table_ch)
    }

    //MODULE: Run Positions of Interest
    if(params.positions_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        positions_of_int_table_ch = Channel.fromPath(params.positions_of_interest, checkIfExists: true)
        POSITIONSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, positions_of_int_table_ch)
    }

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )
}

workflow rsv_i {
    // Error handling to prevent incorrect flags being used
    //check for runpath
    if (params.runpath == null) {
    println 'ERROR!!: Aborting pipeline due missing runpath flags'
    println 'Please provide the file path to the run folder using the runpath flag'
    workflow.exit
    }
    // irma config handling
    if (params.irma_module != 'none' && params.custom_irma_config != null) {
        println 'ERROR!!: Aborting pipeline due to conflicting flags'
        println 'Please provide only the --custom_irma_config flag.'
        println 'Currently, the --irma_module flag is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    if (params.irma_module != 'none') {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'Currently, the --irma_module is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    // primer error handling
    if (params.p == null && params.custom_primers == null) {
        println 'ERROR!!: Aborting pipeline due to missing primer input for trimming'
        println 'Please provide primers using either --p or --custom_primers'
        workflow.exit
    }
    if (params.custom_primers != null && (params.primer_kmer_len == null || params.primer_restrict_window == null)) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'custom_primers flag requires primer_kmer_len and primer_restrict_window flags be specified as well.'
        workflow.exit()
    }
    if (params.custom_primers != null && params.p == null) {
        println 'Using custom primers for trimming'
    }
    if (params.p == 'RSV_CDC_8amplicon_230901') {
        println "using ${params.p} primers for trimming"
    }
    if (params.p != null && (params.p == "varskip" || params.p == "swift_211206" || params.p == "swift" || params.p == 'qiagen' || params.p == 'atric5.3.2' || params.p == 'atric4.1' || params.p == 'atric4')) {
        println "ERROR!!: The primer selection ${params.p} provided is not compatible with RSV"
        println 'Please select the RSV_CDC_8amplicon_230901 primer set or provide a custom primer set'
        workflow.exit()
    }
    if ((params.p == 'varskip' || params.p == 'swift_211206' || params.p == 'swift' || params.p == 'qiagen' || params.p == 'atric5.3.2' || params.p == 'atric4.1' || params.p == 'atric4' || params.p == 'RSV_CDC_8amplicon_230901') && params.custom_primers != null) {
        println 'Both the primer flag and the custom_primer flag have been provided.'
        println 'Using custom primers will be used for trimming'
        params.p = null
    }

    //error handling for variants_of_interest and positions_of_interest flag
    if (params.variants_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The variants_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The positions_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.variants_of_interest == null && params.positions_of_interest == null && params.reference_seq_table != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The reference_seq_table flag is only used when the variants_of_interest or postions_of_interest is used.'
        println 'Please provide a table of variants with the variants_of_interest or the postions_of_interest flag'
        workflow.exit
    }
    if (params.dais_module != null) {
        println 'ERROR!!: The dais_module flag only needs to be specificied with the Find-Variants-Of-Interest or Find-Positions-Of-Interest workflow.'
        workflow.exit
    }
    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()
    if (params.custom_runid != null) {
        runid = params.custom_runid
    } else {
        def path = "${params.runpath}"
        def folder_name = new File(path)
        runid = folder_name.name
    }

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow format
        // Stage fastq files based on profile
        if (params.restage == true){
            fastq_ch = Channel
                .fromPath("${params.runpath}/**/*.fastq.gz", checkIfExists: true)
                .collect()
            sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)
        } else if (params.restage == false ){
            sequences_ch = Channel.fromPath("${params.runpath}/fastqs", checkIfExists: true)
        }

        NEXTFLOWSAMPLESHEETI(samplesheet_ch, sequences_ch, experiment_type_ch)
        // OMICS & Local PLATFORM: END
        // NEXTFLOWSAMPLESHEETI(samplesheet_ch, experiment_type_ch)
        ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETI.out.versions)
        nf_samplesheet_ch = NEXTFLOWSAMPLESHEETI.out.nf_samplesheet

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    } else if (params.amd_platform == true) {
        // save samplesheet as the nf sample
        nf_samplesheet_ch = samplesheet_ch

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(nf_samplesheet_ch)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    }

    // Run or pass READQC subworkflow based on read_qc parameter
    if (params.read_qc == false) {
        println 'Bypassing FastQC and MultiQC steps'
    } else if (params.read_qc == true) {
        // SUBWORKFLOW: Process reads through FastQC and MultiQC
        READQC(INPUT_CHECK.out.reads)
        ch_versions = ch_versions.unique().mix(READQC.out.versions)
    }

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPILLUMINAREADS(nf_samplesheet_ch)
    ch_versions = ch_versions.unique().mix(PREPILLUMINAREADS.out.versions)

    // MODULE: Run IRMA
    IRMA(PREPILLUMINAREADS.out.irma_ch)
    ch_versions = ch_versions.unique().mix(IRMA.out.versions)

    // SUBWORKFLOW: Check IRMA outputs and prepare passed and failed samples
    check_irma_ch = IRMA.out.outputs.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CHECKIRMA(check_irma_ch)

    // MODULE: Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPILLUMINAREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Variants of Interest
    if(params.variants_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        variant_of_int_table_ch = Channel.fromPath(params.variants_of_interest, checkIfExists: true)
        VARIANTSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, variant_of_int_table_ch)
    }

    //MODULE: Run Positions of Interest
    if(params.positions_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        positions_of_int_table_ch = Channel.fromPath(params.positions_of_interest, checkIfExists: true)
        POSITIONSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, positions_of_int_table_ch)
    }

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )
}

workflow rsv_o {
    // Error handling to prevent incorrect flags being used
    //check for runpath
    if (params.runpath == null) {
    println 'ERROR!!: Aborting pipeline due missing runpath flags'
    println 'Please provide the file path to the run folder using the runpath flag'
    workflow.exit
    }
    // irma config handling
    if (params.irma_module != 'none' && params.custom_irma_config != null) {
        println 'ERROR!!: Aborting pipeline due to conflicting flags'
        println 'Please provide only the --custom_irma_config flag.'
        println 'Currently, the --irma_module flag is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    if (params.irma_module != 'none') {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs.'
        println 'Currently, the --irma_module is only compatible with the Flu-Illumina experiment type.'
        workflow.exit
    }
    // primer error handling
    if (params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. RSV-ONT experiment type does not need primers.'
        println 'Please remove --custom_primers to continue.'
        workflow.exit
    } else if (params.p != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. RSV-ONT experiment type does not need primers.'
        println 'Please remove --p to continue.'
        workflow.exit
    }
    if (params.p != null && params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. RSV-ONT experiment type does not need primers.'
        println 'Please remove flags --p and --custom_primers to continue.'
        workflow.exit
    }

    //error handling for variants_of_interest and positions_of_interest flag
    if (params.variants_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The variants_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table == null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The positions_of_interest flag requires that a table of reference seqeunces be provided.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.variants_of_interest == null && params.positions_of_interest == null && params.reference_seq_table != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. The reference_seq_table flag is only used when the variants_of_interest or postions_of_interest is used.'
        println 'Please provide a table of variants with the variants_of_interest or the postions_of_interest flag'
        workflow.exit
    }
    if (params.dais_module != null) {
        println 'ERROR!!: The dais_module flag only needs to be specificied with the Find-Variants-Of-Interest or Find-Positions-Of-Interest workflow.'
        workflow.exit
    }

    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // OMICS & Local PLATFORM: START Concat all fastq files by barcode
        // Prepare new_ch with tuples
        set_up_ch = samplesheet_ch
            .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
        fastq_ch = set_up_ch.map { item ->
            def barcode = item.barcode
            def sample_id = item.sample_id
            def fastq_path = "${params.runpath}/fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, collected_concatenated_fastqs_ch, experiment_type_ch)
        // OMICS & Local END

        // NEXTFLOWSAMPLESHEETO(samplesheet_ch, experiment_type_ch, CONCATFASTQS.out)
        ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETO.out.versions)
        nf_samplesheet_ch = NEXTFLOWSAMPLESHEETO.out.nf_samplesheet

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    } else if (params.amd_platform == true) {
        // save samplesheet as the nf sample
        nf_samplesheet_ch = samplesheet_ch

        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK(nf_samplesheet_ch)
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    }

    //Run or pass READQC subworkflow based on read_qc parameter
    if (params.read_qc == false) {
        println 'Bypassing FastQC and MultiQC steps'
    } else if (params.read_qc == true) {
        // SUBWORKFLOW: Process reads through FastQC and MultiQC
        READQC(INPUT_CHECK.out.reads)
        ch_versions = ch_versions.unique().mix(READQC.out.versions)
    }

    // SUBWORKFLOW: Process ONT reads for IRMA - find chemistry and subsample
    PREPONTREADS(nf_samplesheet_ch)
    ch_versions = ch_versions.unique().mix(PREPONTREADS.out.versions)

    // MODULE: Run IRMA
    IRMA(PREPONTREADS.out.irma_ch)
    ch_versions = ch_versions.unique().mix(IRMA.out.versions)

    // SUBWORKFLOW: Check IRMA outputs and prepare passed and failed samples
    check_irma_ch = IRMA.out.outputs.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CHECKIRMA(check_irma_ch)

    // MODULE: Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Variants of Interest
    if(params.variants_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        variant_of_int_table_ch = Channel.fromPath(params.variants_of_interest, checkIfExists: true)
        VARIANTSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, variant_of_int_table_ch)
    }

    //MODULE: Run Positions of Interest
    if(params.positions_of_interest){
        ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
        positions_of_int_table_ch = Channel.fromPath(params.positions_of_interest, checkIfExists: true)
        POSITIONSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, positions_of_int_table_ch)
    }

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)

    //setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )
}

workflow find_variants_of_int {
    //error handling for variants_of_interest flag
    if (params.variants_of_interest == null && params.reference_seq_table == null && params.dais_module == null ||
    params.variants_of_interest != null && params.reference_seq_table == null && params.dais_module == null ||
    params.variants_of_interest == null && params.reference_seq_table != null && params.dais_module == null ||
    params.variants_of_interest == null && params.reference_seq_table == null && params.dais_module != null) {
        println 'ERROR!!: This workflow requires the variants_of_interest, reference_seq_table and dais_module flags be specificied.'
        workflow.exit
    }
    if (params.variants_of_interest != null && params.reference_seq_table == null && params.dais_module != null) {
        println 'ERROR!!: This workflow requires the variants_of_interest, reference_seq_table and dais_module flags be specificied.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.variants_of_interest == null && params.reference_seq_table != null && params.dais_module != null) {
        println 'ERROR!!: This workflow requires the variants_of_interest, reference_seq_table and dais_module flags be specificied.'
        println 'Please provide a table of variants with the variants_of_interest flag'
        workflow.exit
    }
    if (params.variants_of_interest != null && params.reference_seq_table != null && params.dais_module == null) {
        println 'ERROR!!: This workflow requires the variants_of_interest, reference_seq_table and dais_module flags be specificied.'
        println 'Please provide the dais module needed (influenza,betacoronavirus or rsv) with the dais_module flag'
        workflow.exit
    }
    if (params.positions_of_interest != null) {
        println 'ERROR!!: Please run the Find-Positions-Of-Interest workflow if you would like to used the positions_of_interest flag.'
        workflow.exit
    }

    // Initializing parameters
    dais_input_ch = Channel.fromPath(params.input, checkIfExists: true)
    ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
    variant_of_int_table_ch = Channel.fromPath(params.variants_of_interest, checkIfExists: true)
    ch_versions = Channel.empty()
    dais_module_ch = Channel.value(params.dais_module).map { it.toUpperCase() }
    //If sourcepath flag is given, then it will use the sourcepath to point to the reference files and support files in prepareIRMAjson and staticHTML
    if (params.sourcepath == null) {
        support_file_path = Channel.fromPath(projectDir, checkIfExists: true)
    } else {
        support_file_path = Channel.fromPath(params.sourcepath, checkIfExists: true)
    }

    //MODULE: Check mira version
    if (params.check_version == false){
        println("MIRA version not checked")
        mira_version_ch = "MIRA version not checked"
    } else {
        CHECKMIRAVERSION(support_file_path)
        mira_version_ch = CHECKMIRAVERSION.out.view()
    }
    //Setting up to put MIRA-NF version checking in email
    CHECKMIRAVERSION.out.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )

    //MODULE: Run Dais Ribosome
    DAISRIBOSOME(dais_input_ch, dais_module_ch)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Variants of Interest
    VARIANTSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, variant_of_int_table_ch, dais_module_ch)

}

workflow find_positions_of_int {
    //error handling for positions_of_interest flag
    if (params.positions_of_interest == null && params.reference_seq_table == null && params.dais_module == null ||
    params.positions_of_interest != null && params.reference_seq_table == null && params.dais_module == null ||
    params.positions_of_interest == null && params.reference_seq_table != null && params.dais_module == null ||
    params.positions_of_interest == null && params.reference_seq_table == null && params.dais_module != null) {
        println 'ERROR!!: This workflow requires the positions_of_interest, reference_seq_table and dais_module flags be specificied.'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table == null && params.dais_module != null) {
        println 'ERROR!!: This workflow requires the positions_of_interest, reference_seq_table and dais_module flags be specificied.'
        println 'Please provide a table of reference seqeunces with the reference_seq_table flag'
        workflow.exit
    }
    if (params.positions_of_interest == null && params.reference_seq_table != null && params.dais_module != null) {
        println 'ERROR!!: This workflow requires the positions_of_interest, reference_seq_table and dais_module flags be specificied.'
        println 'Please provide a table of variants with the positions_of_interest flag'
        workflow.exit
    }
    if (params.positions_of_interest != null && params.reference_seq_table != null && params.dais_module == null) {
        println 'ERROR!!: This workflow requires the positions_of_interest, reference_seq_table and dais_module flags be specificied.'
        println 'Please provide the dais module needed (influenza,betacoronavirus or rsv) with the dais_module flag'
        workflow.exit
    }
    if (params.variants_of_interest != null) {
        println 'ERROR!!: Please run the Find-Variants-Of-Interest workflow if you would like to used the variantsS_of_interest flag.'
        workflow.exit
    }

    // Initializing parameters
    dais_input_ch = Channel.fromPath(params.input, checkIfExists: true)
    ref_table_ch = Channel.fromPath(params.reference_seq_table, checkIfExists: true)
    positions_of_interest_ch = Channel.fromPath(params.positions_of_interest, checkIfExists: true)
    ch_versions = Channel.empty()
    dais_module_ch = Channel.value(params.dais_module).map { it.toUpperCase() }
    //If sourcepath flag is given, then it will use the sourcepath to point to the reference files and support files in prepareIRMAjson and staticHTML
    if (params.sourcepath == null) {
        support_file_path = Channel.fromPath(projectDir, checkIfExists: true)
    } else {
        support_file_path = Channel.fromPath(params.sourcepath, checkIfExists: true)
    }

    //MODULE: Check mira version
    if (params.check_version == false){
        println("MIRA version not checked")
        mira_version_ch = "MIRA version not checked"
    } else {
        CHECKMIRAVERSION(support_file_path)
        mira_version_ch = CHECKMIRAVERSION.out.view()
    }
    //Setting up to put MIRA-NF version checking in email
    CHECKMIRAVERSION.out.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${params.outdir}/pipeline_info",
            keepHeader: false
        )


    //MODULE: Run Dais Ribosome
    DAISRIBOSOME(dais_input_ch, dais_module_ch)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //MODULE: Run Positions of Interest
    POSITIONSOFINT(DAISRIBOSOME.out.dais_seq_output, ref_table_ch, positions_of_interest_ch, dais_module_ch)

}
// MAIN WORKFLOW
// Decides which experiment type workflow to run based on experiment parameter given
workflow MIRA {
    if (params.e == 'Flu-Illumina') {
        flu_i()
} else if (params.e == 'Flu-ONT') {
        flu_o()
    } else if (params.e == 'SC2-Spike-Only-ONT') {
        sc2_spike_o()
    } else if (params.e == 'SC2-Whole-Genome-ONT') {
        sc2_wgs_o()
    } else if (params.e == 'SC2-Whole-Genome-Illumina') {
        sc2_wgs_i()
    } else if (params.e == 'RSV-Illumina') {
        rsv_i()
    } else if (params.e == 'RSV-ONT') {
        rsv_o()
    } else if (params.e == 'Find-Variants-Of-Interest') {
       find_variants_of_int()
    } else if (params.e == 'Find-Positions-Of-Interest') {
       find_positions_of_int()
    }
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.email) {
    workflow.onComplete {
        if (workflow.success == true) {
            if (params.e != 'Find-Variants-Of-Interest' && params.e != 'Find-Positions-Of-Interest') {
    def versionPath = "${params.outdir}/pipeline_info/mira_version_check.txt"
    def fileContent = new File(versionPath).exists() ? new File(versionPath).text : "Version file not found."
    def path = "${params.runpath}"
    def folder_name = new File(path)
    def basename = folder_name.name
    def ac_file = new File("${params.outdir}/aggregate_outputs/mira-reports/mira_${basename}_amended_consensus.fasta")

    if (ac_file.exists()) {
        def final_files = [
            "${params.outdir}/aggregate_outputs/csv-reports/mira_${basename}_summary.csv",
            "${params.outdir}/aggregate_outputs/mira-reports/mira_${basename}_amended_consensus.fasta"
        ]
        def msg = """
        Pipeline execution summary
        Completed at: ${workflow.complete}
        Duration    : ${workflow.duration}
        Success     : ${workflow.success}
        workDir     : ${workflow.workDir}
        outDir      : ${params.outdir}
        exit status : ${workflow.exitStatus}
        ${fileContent}
        """
        .stripIndent()

        sendMail(
            to: params.email,
            from: 'mira-nf@mail.biotech.cdc.gov',
            subject: 'MIRA-NF pipeline execution',
            body: msg,
            attach: final_files
        )
    } else {
        def final_files = [
            "${params.outdir}/aggregate_outputs/csv-reports/mira_${basename}_summary.csv"
        ]
        def msg = """
        Pipeline execution summary
        Completed at: ${workflow.complete}
        Duration    : ${workflow.duration}
        Success     : ${workflow.success}
        workDir     : ${workflow.workDir}
        outDir      : ${params.outdir}
        exit status : ${workflow.exitStatus}
        No amended consensus was created!
        """
        .stripIndent()

        sendMail(
            to: params.email,
            from: 'mira-nf@mail.biotech.cdc.gov',
            subject: 'MIRA-NF pipeline execution',
            body: msg,
            attach: final_files
        )
    }
} else if (params.e == 'Find-Variants-Of-Interest' || params.e == 'Find-Positions-Of-Interest') {
    def versionPath = "${params.outdir}/pipeline_info/mira_version_check.txt"
    def fileContent = new File(versionPath).exists() ? new File(versionPath).text : "Version file not found."
    def msg = """
    Pipeline execution summary
    Completed at: ${workflow.complete}
    Duration    : ${workflow.duration}
    Success     : ${workflow.success}
    workDir     : ${workflow.workDir}
    outDir      : ${params.outdir}
    exit status : ${workflow.exitStatus}
    ${fileContent}
    Variants of interest workflow has run successfully.
    """
    .stripIndent()

    sendMail(
        to: params.email,
        from: 'mira-nf@mail.biotech.cdc.gov',
        subject: 'MIRA-NF pipeline execution',
        body: msg
    )
}
        } else if (workflow.success == false) {
            def msg = """
       Pipeline execution summary
       Completed at: ${workflow.complete}
       Duration    : ${workflow.duration}
       Success     : ${workflow.success}
       workDir     : ${workflow.workDir}
       outDir      : ${params.outdir}
       exit status : ${workflow.exitStatus}
       """
       .stripIndent()

            sendMail(to: params.email, from:'mira-nf@mail.biotech.cdc.gov', subject: 'MIRA-NF pipeline execution', body:msg)
        }
    }

    workflow.onError {
        if (workflow.errorReport.contains('Process requirement exceeds available memory')) {
            println('🛑 Default resources exceed availability 🛑 ')
            println('💡 See here on how to configure pipeline: https://nf-co.re/docs/usage/configuration#tuning-workflow-resources 💡')
        }
    }
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
