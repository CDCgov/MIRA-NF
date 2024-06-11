/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL PLUGINS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowCli.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { CONCATFASTQS         } from "${launchDir}/modules/local/concatfastqs"
include { NEXTFLOWSAMPLESHEETI } from "${launchDir}/modules/local/nextflowsamplesheeti"
include { NEXTFLOWSAMPLESHEETO } from "${launchDir}/modules/local/nextflowsamplesheeto"
include { INPUT_CHECK          } from "${launchDir}/subworkflows/local/input_check"
include { READQC               } from "${launchDir}/subworkflows/local/readqc"
include { PREPILLUMINAREADS    } from "${launchDir}/subworkflows/local/prepilluminareads"
include { PREPONTREADS         } from "${launchDir}/subworkflows/local/prepontreads"
include { IRMA                 } from "${launchDir}/modules/local/irma"
include { CHECKIRMA            } from "${launchDir}/subworkflows/local/checkirma"
include { DAISRIBOSOME         } from "${launchDir}/modules/local/daisribosome"
include { PREPAREREPORTS       } from "${launchDir}/subworkflows/local/preparereports"
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from "${launchDir}/modules/nf-core/custom/dumpsoftwareversions/main"
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//input is the sample sheet
//outdir is the run direcotry

workflow flu_i {
    //Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    // Convert the samplesheet to a nextflow format
    NEXTFLOWSAMPLESHEETI(samplesheet_ch, experiment_type_ch)
    ch_versions = ch_versions.mix(NEXTFLOWSAMPLESHEETI.out.versions)

    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    // SUBWORKFLOW: Process reads through FastQC and MultiQC
    READQC(INPUT_CHECK.out.reads, summary_params)
    ch_versions = ch_versions.unique().mix(READQC.out.versions)

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPILLUMINAREADS(NEXTFLOWSAMPLESHEETI.out.nf_samplesheet)
    ch_versions = ch_versions.unique().mix(PREPILLUMINAREADS.out.versions)

    // Run IRMA
    IRMA(PREPILLUMINAREADS.out.irma_ch)
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
    DAISRIBOSOME(CHECKIRMA.out, PREPILLUMINAREADS.out.dais_module)
    ch_versions = ch_versions.unique().mix(DAISRIBOSOME.out.versions)

    //Create reports
    PREPAREREPORTS(DAISRIBOSOME.out.dais_outputs.collect())
    ch_versions = ch_versions.unique().mix(PREPAREREPORTS.out.versions)

    //work on this more later
    ch_versions.unique().collectFile(name: 'collated_versions.yml').view()

//
}

workflow flu_o {
    //Initializing parameters
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    run_ID_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    experiment_type_ch = Channel.value(params.e)
    ch_versions = Channel.empty()

    //Concat all fastq files by barcode
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
    READQC(INPUT_CHECK.out.reads, summary_params)
    ch_versions = ch_versions.unique().mix(READQC.out.versions)

    // SUBWORKFLOW: Process illumina reads for IRMA - find chemistry and subsample
    PREPONTREADS(NEXTFLOWSAMPLESHEETO.out.nf_samplesheet)
    //ch_versions = ch_versions.unique().mix(PREPONTREADS.out.versions)

    println 'Flu ONT workflow under construction'
}

workflow sc2_spike_o {
    println 'SARS-CoV-2 Spike ONT workflow under construction'
}

workflow sc2_wgs_o {
    println 'SARS-CoV-2 WGS ONT workflow under construction'
}

workflow sc2_wgs_i {
    println 'SARS-CoV-2 WGS Illumina workflow under construction'
}

workflow CLI {
    if (params.e == 'Flu_Illumina') {
        flu_i()
} else if (params.e == 'Flu-ONT') {
        flu_o()
    } else if (params.e == 'SC2-Spike-Only-ONT') {
        sc2_spike_o()
    } else if (params.e == 'SC2-Whole-Genome-ONT') {
        sc2_wg_o()
    } else if (params.e == 'SC2-Whole-Genome-Illumina') {
        sc2_wg_i()
    }
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        def msg = """
       Pipeline execution summary
       Completed at: ${workflow.complete}
       Duration    : ${workflow.duration}
       Success     : ${workflow.success}
       workDir     : ${workflow.workDir}
       exit status : ${workflow.exitStatus}
       """
       .stripIndent()

        sendMail(to: params.email , subject: 'Nextflow pipeline execution', body:msg, attach: './summary.xlsx')
    }
}

workflow.onError {
    if (workflow.errorReport.contains('Process requirement exceeds available memory')) {
        println('🛑 Default resources exceed availability 🛑 ')
        println('💡 See here on how to configure pipeline: https://nf-co.re/docs/usage/configuration#tuning-workflow-resources 💡')
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
