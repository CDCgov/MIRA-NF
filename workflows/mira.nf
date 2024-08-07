/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
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

    // MODULE: Convert the samplesheet to a nextflow format
    NEXTFLOWSAMPLESHEETI(samplesheet_ch, experiment_type_ch)
    ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETI.out.versions)

    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // SUBWORKFLOW: Process reads through FastQC and MultiQC
    READQC(INPUT_CHECK.out.reads)
    ch_versions = ch_versions.unique().mix(READQC.out.versions)

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPILLUMINAREADS(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
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
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)
}

workflow flu_o {
    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    // MODULE: Concat all fastq files by barcode
    set_up_ch = samplesheet_ch
        .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
    new_ch = set_up_ch.map { item ->
        [item.barcode, item.sample_id] }
    CONCATFASTQS(new_ch)

    // MODULE: Convert the samplesheet to a nextflow format
    NEXTFLOWSAMPLESHEETO(samplesheet_ch, run_ID_ch, experiment_type_ch, CONCATFASTQS.out)
    ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETO.out.versions)

    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    INPUT_CHECK(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // SUBWORKFLOW: Process reads through FastQC and MultiQC
    READQC(INPUT_CHECK.out.reads)
    ch_versions = ch_versions.unique().mix(READQC.out.versions)

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPONTREADS(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
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
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)
}

workflow sc2_spike_o {
    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    // MODULE: Concat all fastq files by barcode
    set_up_ch = samplesheet_ch
        .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
    new_ch = set_up_ch.map { item ->
        [item.barcode, item.sample_id] }
    CONCATFASTQS(new_ch)

    // Convert the samplesheet to a nextflow format
    NEXTFLOWSAMPLESHEETO(samplesheet_ch, run_ID_ch, experiment_type_ch, CONCATFASTQS.out)
    ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETO.out.versions)

    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    INPUT_CHECK(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // SUBWORKFLOW: Process reads through FastQC and MultiQC
    READQC(INPUT_CHECK.out.reads)
    ch_versions = ch_versions.unique().mix(READQC.out.versions)

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPONTREADS(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
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
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)
}

workflow sc2_wgs_o {
    // Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    // MODULE: Concat all fastq files by barcode
    set_up_ch = samplesheet_ch
        .splitCsv(header: ['barcode', 'sample_id', 'sample_type'], skip: 1)
    new_ch = set_up_ch.map { item ->
        [item.barcode, item.sample_id] }
    CONCATFASTQS(new_ch)

    // Convert the samplesheet to a nextflow format
    NEXTFLOWSAMPLESHEETO(samplesheet_ch, run_ID_ch, experiment_type_ch, CONCATFASTQS.out)
    ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETO.out.versions)

    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // SUBWORKFLOW: Process reads through FastQC and MultiQC
    READQC(INPUT_CHECK.out.reads)
    ch_versions = ch_versions.unique().mix(READQC.out.versions)

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPONTREADS(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
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
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)
}

workflow sc2_wgs_i {
    //Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    // Convert the samplesheet to a nextflow format
    NEXTFLOWSAMPLESHEETI(samplesheet_ch, experiment_type_ch)
    ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETI.out.versions)

    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    INPUT_CHECK(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // SUBWORKFLOW: Process reads through FastQC and MultiQC
    READQC(INPUT_CHECK.out.reads)
    ch_versions = ch_versions.unique().mix(READQC.out.versions)

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPILLUMINAREADS(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
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
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect(), ch_versions)
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

            sendMail(to: params.email, from:'mira-nf@mail.biotech.cdc.gov', subject: 'Nextflow pipeline execution', body:msg, attach: "${params.outdir}/email_summary.xlsx")
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

            sendMail(to: params.email , subject: 'Nextflow pipeline execution', body:msg)
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
