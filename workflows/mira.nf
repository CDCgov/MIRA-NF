/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { STAGES3FILES        } from '../modules/local/stages3files'
// include { CONCATFASTQS         } from '../modules/local/concatfastqs'
include { NEXTFLOWSAMPLESHEETI } from '../modules/local/nextflowsamplesheeti'
include { NEXTFLOWSAMPLESHEETO } from '../modules/local/nextflowsamplesheeto'
include { INPUT_CHECK          } from '../subworkflows/local/input_check'
include { READQC               } from '../subworkflows/local/readqc'
include { PREPILLUMINAREADS    } from '../subworkflows/local/prepilluminareads'
include { PREPONTREADS         } from '../subworkflows/local/prepontreads'
include { IRMA                 } from '../modules/local/irma'
include { CHECKIRMA            } from '../subworkflows/local/checkirma'
include { CREATEBLASTNINPUT    } from '../modules/local/createblastninput'
include { BLASTN               } from '../modules/local/blastn'
include { DAISRIBOSOME         } from '../modules/local/daisribosome'
include { PREPAREREPORTS       } from '../subworkflows/local/preparereports'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// input is the sample sheet
// outdir is the run directory

workflow flu_i {
    // Error handling to prevent incorrect flags being used
    // irma config handling
    if (params.irma_module != 'none' && params.custom_irma_config != null) {
        println 'ERROR!!: Aborting pipeline due to conflicting flags'
        println 'Please provide either the --irma_module or --custom_irma_config flag.'
        println 'They cannot be used together.'
        workflow.exit
    }
    // primer error handling
    if (params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. Flu-Illumina experiment type does not need primers.'
        println 'Please remove --custom_primers to continue.'
        workflow.exit
    } else if (params.p != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. Flu-Illumina experiment type does not need primers.'
        println 'Please remove --p to continue.'
        workflow.exit
    }
    if (params.p != null && params.custom_primers != null) {
        println 'ERROR!!: Aborting pipeline due to incorrect inputs. Flu-Illumina experiment type does not need primers.'
        println 'Please remove flags --p and --custom_primers to continue.'
        workflow.exit
    }

    // Normalize paths to absolute paths
    def input_path = file(params.input).toAbsolutePath()
    def runpath_path = file(params.runpath).toAbsolutePath()
    def output_path = file(params.outdir).toAbsolutePath()

    // Initialize channels
    samplesheet_ch = Channel.fromPath(input_path, checkIfExists: true)
    run_ID_ch = Channel.fromPath(runpath_path, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow
        // OMICS & Local PLATFORM: Stage all fastq files
        fastq_ch = Channel
                .fromPath("${runpath_path}/**/*.fastq.gz", checkIfExists: true)
                .collect()

        def runid = runpath_path.tokenize('/').last()
        sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)

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

    //extract PB2 segment for BLASTN
    CREATEBLASTNINPUT(check_irma_ch)

    // MODULE: Run BLASTN
    BLASTN(CREATEBLASTNINPUT.out)
    ch_versions = ch_versions.unique().mix(BLASTN.out.versions)

    // MODULE: Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPILLUMINAREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${output_path}/pipeline_info",
            keepHeader: false
        )
}

workflow flu_o {
    // Error handling to prevent incorrect flags being used
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

    // Normalize paths to absolute paths
    def input_path = file(params.input).toAbsolutePath()
    def runpath_path = file(params.runpath).toAbsolutePath()
    def output_path = file(params.outdir).toAbsolutePath()

    // Initializing channels
    samplesheet_ch = Channel.fromPath(input_path, checkIfExists: true)
    run_ID_ch = Channel.fromPath(runpath_path, checkIfExists: true)
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
            def fastq_path = "${runpath_path}/fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        //concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        //collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, output_path, experiment_type_ch)
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

    //extract PB2 segment for BLASTN
    CREATEBLASTNINPUT(check_irma_ch)

    // MODULE: Run BLASTN
    BLASTN(CREATEBLASTNINPUT.out)
    ch_versions = ch_versions.unique().mix(BLASTN.out.versions)

    // MODULE: Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out.dais_ch, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${output_path}/pipeline_info",
            keepHeader: false
        )
}

workflow sc2_spike_o {
    // Error handling to prevent incorrect flags being used
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

    // Normalize paths to absolute paths
    def input_path = file(params.input).toAbsolutePath()
    def runpath_path = file(params.runpath).toAbsolutePath()
    def output_path = file(params.outdir).toAbsolutePath()

    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()
    samplesheet_ch = Channel.fromPath(input_path, checkIfExists: true)

    if (params.amd_platform == false) {
        // OMICS & Local PLATFORM: START Concat all fastq files by barcode
        set_up_ch = samplesheet_ch
            .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
        fastq_ch = set_up_ch.map { item ->
            def barcode = item.barcode
            def sample_id = item.sample_id
            // def fastq_path = "${params.runpath}/**/${barcode}/*.fastq.gz"; // it was not working with **, so I changed it to fastq_pass
            def fastq_path = "${runpath_path}/fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        //concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        //collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()
        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, output_path, experiment_type_ch)
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

    // Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${output_path}/pipeline_info",
            keepHeader: false
        )
}

workflow sc2_wgs_o {
    // Error handling to prevent incorrect flags being used
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

    // Normalize paths to absolute paths
    def input_path = file(params.input).toAbsolutePath()
    def runpath_path = file(params.runpath).toAbsolutePath()
    def output_path = file(params.outdir).toAbsolutePath()

    // Initializing channels
    samplesheet_ch = Channel.fromPath(input_path, checkIfExists: true)
    run_ID_ch = Channel.fromPath(runpath_path, checkIfExists: true)
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
            def fastq_path = "${runpath_path}/fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        //concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        //collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, output_path, experiment_type_ch)
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

    //SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)

    //setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${output_path}/pipeline_info",
            keepHeader: false
        )
}

workflow sc2_wgs_i {
    //Error handling to prevent incorrect flags being used
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
    } else if (params.p == 'RSV_CDC_8amplicon_230901') {
        println 'ERROR!!: The primer selection provided is not compatible with SARS-CoV-2'
        println 'Please select the one of the SARS-CoV-2 primer sets or provide a custom primer set'
        workflow.exit
    } else if (params.custom_primers != null) {
        println 'Using custom primers for trimming'
    } else if (params.p == 'varskip' || 'swift_211206' || 'swift' || 'qiagen' || 'atric5.3.2' || 'atric4.1' || 'atric4') {
        println "using ${params.p} primers for trimming"
    } else if (params.p == 'varskip' || 'swift_211206' || 'swift' || 'qiagen' || 'atric5.3.2' || 'atric4.1' || 'atric4' && params.custom_primers != null) {
        println 'using custom primers for trimming'
        params.p = null
    }

    // Normalize paths to absolute paths
    def input_path = file(params.input).toAbsolutePath()
    def runpath_path = file(params.runpath).toAbsolutePath()
    def output_path = file(params.outdir).toAbsolutePath()

    //Initializing parameters
    samplesheet_ch = Channel.fromPath(input_path, checkIfExists: true)
    run_ID_ch = Channel.fromPath(runpath_path, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow format
        // OMICS & Local PLATFORM: Stage all fastq files
        fastq_ch = Channel
                .fromPath("${runpath_path}/**/*.fastq.gz", checkIfExists: true)
                .collect()

        def runid = runpath_path.tokenize('/').last()
        sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)

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

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${output_path}/pipeline_info",
            keepHeader: false
        )
}

workflow rsv_i {
    // Error handling to prevent incorrect flags being used
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
    } else if (params.custom_primers != null) {
        println 'Using custom primers for trimming'
    } else if (params.p == 'RSV_CDC_8amplicon_230901') {
        println "using ${params.p} primers for trimming"
    }else if (params.p == 'varskip' || 'swift_211206' || 'swift' || 'qiagen' || 'atric5.3.2' || 'atric4.1' || 'atric4') {
        println 'ERROR!!: The primer selection provided is not compatible with RSV'
        println 'Please select the RSV_CDC_8amplicon_230901 primer set or provide a custom primer set'
        workflow.exit
    } else if (params.p == 'varskip' || 'swift_211206' || 'swift' || 'qiagen' || 'atric5.3.2' || 'atric4.1' || 'atric4' || 'RSV_CDC_8amplicon_230901' && params.custom_primers != null) {
        println 'using custom primers for trimming'
        params.p = null
    }

    // Normalize paths to absolute paths
    def input_path = file(params.input).toAbsolutePath()
    def runpath_path = file(params.runpath).toAbsolutePath()
    def output_path = file(params.outdir).toAbsolutePath()

    // Initializing parameters
    samplesheet_ch = Channel.fromPath(input_path, checkIfExists: true)
    run_ID_ch = Channel.fromPath(runpath_path, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow format
        // OMICS & Local PLATFORM: Stage all fastq files
        fastq_ch = Channel
                .fromPath("${runpath_path}/**/*.fastq.gz", checkIfExists: true)
                .collect()

        def runid = runpath_path.tokenize('/').last()
        sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)

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

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)

    // setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${output_path}/pipeline_info",
            keepHeader: false
        )
}

workflow rsv_o {
    // Error handling to prevent incorrect flags being used
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

    // Normalize paths to absolute paths
    def input_path = file(params.input).toAbsolutePath()
    def runpath_path = file(params.runpath).toAbsolutePath()
    def output_path = file(params.outdir).toAbsolutePath()

    // Initializing parameters
    samplesheet_ch = Channel.fromPath(input_path, checkIfExists: true)
    run_ID_ch = Channel.fromPath(runpath_path, checkIfExists: true)
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
            def fastq_path = "${runpath_path}/fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        //concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        //collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, output_path, experiment_type_ch)
        // OMICS & Local END

        // NEXTFLOWSAMPLESHEETO(samplesheet_ch, run_ID_ch, experiment_type_ch, CONCATFASTQS.out)
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

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)

    //setting up to put MIRA-NF version checking in email
    PREPAREREPORTS.out.mira_version_ch.collectFile(
            name: 'mira_version_check.txt',
            storeDir:"${output_path}/pipeline_info",
            keepHeader: false
        )
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
            def input_path = file(params.input).toAbsolutePath()
            def runpath_path = file(params.runpath).toAbsolutePath()
            def output_path = file(params.outdir).toAbsolutePath()
            def versionPath = "${output_path}/pipeline_info/mira_version_check.txt"
            def fileContent = new File(versionPath).text
            def path = "${runpath_path}"
            def folder_name = new File(path)
            def basename = folder_name.name
            def ac_file = new File("${output_path}/aggregate_outputs/mira-reports/MIRA_" + basename + '_amended_consensus.fasta')
            if (ac_file.exists()) {
                /* groovylint-disable-next-line LineLength */
                def final_files = ["${output_path}/aggregate_outputs/mira-reports/MIRA_" + basename + '_summary.xlsx', "${output_path}/aggregate_outputs/mira-reports/MIRA_" + basename + '_amended_consensus.fasta']
                def msg = """
                Pipeline execution summary
                Completed at: ${workflow.complete}
                Duration    : ${workflow.duration}
                Success     : ${workflow.success}
                workDir     : ${workflow.workDir}
                outDir      : ${output_path}
                exit status : ${workflow.exitStatus}
                ${fileContent}
                """
                .stripIndent()

                    sendMail(to: params.email, from:'mira-nf@mail.biotech.cdc.gov', subject: 'MIRA-NF pipeline execution', body:msg, attach:final_files)
            } else {
                def final_files = ["${output_path}/aggregate_outputs/mira-reports/MIRA_" + basename + '_summary.xlsx']
                def msg = """
                Pipeline execution summary
                Completed at: ${workflow.complete}
                Duration    : ${workflow.duration}
                Success     : ${workflow.success}
                workDir     : ${workflow.workDir}
                outDir      : ${output_path}
                exit status : ${workflow.exitStatus}
                No amended consensus was created!
                """
                .stripIndent()

                    sendMail(to: params.email, from:'mira-nf@mail.biotech.cdc.gov', subject: 'MIRA-NF pipeline execution', body:msg, attach:final_files)
            }
        } else if (workflow.success == false) {
            def msg = """
       Pipeline execution summary
       Completed at: ${workflow.complete}
       Duration    : ${workflow.duration}
       Success     : ${workflow.success}
       workDir     : ${workflow.workDir}
       outDir      : ${output_path}
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
