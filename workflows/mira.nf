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
include { PREPAREREPORTS       } from '../subworkflows/local/preparereports'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//input is the sample sheet
//outdir is the run direcotry

workflow flu_i {
    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow
        fastq_ch = Channel
                .fromPath("${params.runpath}/**/*.fastq.gz", checkIfExists: true)
                .collect()

        def runid = params.runpath.tokenize('/').last()
        sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)

        NEXTFLOWSAMPLESHEETI(samplesheet_ch, sequences_ch, experiment_type_ch)

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

    //Run or pass READQC subworkflow based on read_qc parameter
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
    DAISRIBOSOME(CHECKIRMA.out, PREPILLUMINAREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)
}

workflow flu_o {
    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
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
            def fastq_path = "${params.runpath}/**/${barcode}/"
            tuple(barcode, sample_id, fastq_path)
        }
        concatenated_fastqs_ch = CONCATFASTQS(fastq_ch)
        collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, collected_concatenated_fastqs_ch, experiment_type_ch)

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
    DAISRIBOSOME(CHECKIRMA.out, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)
}

workflow sc2_spike_o {
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)

    if (params.amd_platform == false) {
        // MODULE: Concat all fastq files by barcode
        // Prepare new_ch with tuples
        set_up_ch = samplesheet_ch
            .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
        fastq_ch = set_up_ch.map { item ->
            def barcode = item.barcode
            def sample_id = item.sample_id
            def fastq_path = "${params.runpath}/**/${barcode}/"
            tuple(barcode, sample_id, fastq_path)
        }
        concatenated_fastqs_ch = CONCATFASTQS(fastq_ch)
        collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, collected_concatenated_fastqs_ch, experiment_type_ch)

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

    //SUBWORKFLOW: Check IRMA outputs and prepare passed and failed samples
    check_irma_ch = IRMA.out.outputs.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CHECKIRMA(check_irma_ch)

    //Run Dais Ribosome
    DAISRIBOSOME(CHECKIRMA.out, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)
}

workflow sc2_wgs_o {
    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
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
            def fastq_path = "${params.runpath}/**/${barcode}/"
            tuple(barcode, sample_id, fastq_path)
        }
        concatenated_fastqs_ch = CONCATFASTQS(fastq_ch)
        collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, collected_concatenated_fastqs_ch, experiment_type_ch)

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
    DAISRIBOSOME(CHECKIRMA.out, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)
}

workflow sc2_wgs_i {
    //checking that primer parameter chas been provided before proceding through workflow - aborts pipeline if none are given
    if (params.p == null && params.custom_primers == null) {
        println 'ERROR!!: Abosrting pipeline due to missing primer input for trimming'
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

    //Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow format
        //Stageall fastq files
        fastq_ch = Channel
                .fromPath("${params.runpath}/**/*.fastq.gz", checkIfExists: true)
                .collect()

        def runid = params.runpath.tokenize('/').last()
        sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)

        NEXTFLOWSAMPLESHEETI(samplesheet_ch, sequences_ch, experiment_type_ch)

        //NEXTFLOWSAMPLESHEETI(samplesheet_ch, experiment_type_ch)
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

    //Run or pass READQC subworkflow based on read_qc parameter
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
    DAISRIBOSOME(CHECKIRMA.out, PREPILLUMINAREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)
}

workflow rsv_i {
    if (params.p == null && params.custom_primers == null) {
        println 'ERROR!!: Abosrting pipeline due to missing primer input for trimming'
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

    //Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    if (params.amd_platform == false) {
        // MODULE: Convert the samplesheet to a nextflow format
        fastq_ch = Channel
                .fromPath("${params.runpath}/**/*.fastq.gz", checkIfExists: true)
                .collect()

        def runid = params.runpath.tokenize('/').last()
        sequences_ch = STAGES3FILES(runid, 'fastqs', fastq_ch)

        NEXTFLOWSAMPLESHEETI(samplesheet_ch, sequences_ch, experiment_type_ch)

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

    //Run or pass READQC subworkflow based on read_qc parameter
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
    DAISRIBOSOME(CHECKIRMA.out, PREPILLUMINAREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)
}

workflow rsv_o {
    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
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
            def fastq_path = "${params.runpath}fastq_pass/${barcode}/*.fastq.gz"
            tuple(barcode, sample_id, file(fastq_path))
        }
        concatenated_fastqs_ch = fastq_ch | CONCATFASTQS
        collected_concatenated_fastqs_ch = concatenated_fastqs_ch.collect()

        // MODULE: Convert the samplesheet to a nextflow format
        NEXTFLOWSAMPLESHEETO(samplesheet_ch, collected_concatenated_fastqs_ch, experiment_type_ch)

        //NEXTFLOWSAMPLESHEETO(samplesheet_ch, run_ID_ch, experiment_type_ch, CONCATFASTQS.out)
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
    DAISRIBOSOME(CHECKIRMA.out, PREPONTREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    // SUBWORKFLOW: Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), nf_samplesheet_ch, ch_versions)
}
// MAIN WORKFLOW
// Decides which experiment type workflow to run based on experiemtn parameter given
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
            def path = "${params.runpath}"
            def folder_name = new File(path)
            def basename = folder_name.name
            def ac_file = new File("${params.outdir}/aggregate_outputs/mira-reports/MIRA_" + basename + '_amended_consensus.fasta')
            if (ac_file.exists()) {
                /* groovylint-disable-next-line LineLength */
                def final_files = ["${params.outdir}/aggregate_outputs/mira-reports/MIRA_" + basename + '_summary.xlsx', "${params.outdir}/aggregate_outputs/mira-reports/MIRA_" + basename + '_amended_consensus.fasta']
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

                    sendMail(to: params.email, from:'mira-nf@mail.biotech.cdc.gov', subject: 'MIRA-NF pipeline execution', body:msg, attach:final_files)
            } else {
                def final_files = ["${params.outdir}/aggregate_outputs/mira-reports/MIRA_" + basename + '_summary.xlsx']
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

                    sendMail(to: params.email, from:'mira-nf@mail.biotech.cdc.gov', subject: 'MIRA-NF pipeline execution', body:msg, attach:final_files)
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
