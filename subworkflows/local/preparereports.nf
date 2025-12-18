/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { CHECKMIRAVERSION     } from '../../modules/local/checkmiraversion'
include { PREPAREMIRAREPORTS   } from '../../modules/local/preparemirareports'
include { PREPAREMIRAREPORTSWITHPARQ   } from '../../modules/local/preparemirareportswithparq'

workflow PREPAREREPORTS {
    take:
    dais_outputs_ch // channel: holds dais outputs
    ch_versions // channel: holds all previous version

    main:
    platform = Channel.empty()
    virus = Channel.empty()
    samplesheet_ch = Channel.fromPath(params.input, checkIfExists: true)
    //Get run id
    if (params.custom_runid != null) {
        runid = params.custom_runid
    } else {
        def path = "${params.runpath}"
        def folder_name = new File(path)
        runid = folder_name.name
    }

    //Get irma directory
    irma_dir_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    input_ch = Channel.fromPath(params.input, checkIfExists: true)
    //If sourcepath flag is given, then it will use the sourcepath to point to the reference files and support files in preparemirareports
    if (params.sourcepath == null) {
        support_file_path = Channel.fromPath(projectDir, checkIfExists: true)
    } else {
        support_file_path = Channel.fromPath(params.sourcepath, checkIfExists: true)
    }

    //check mira version
    if (params.check_version == false){
        println("MIRA version not checked")
        mira_version_ch = "MIRA version not checked"
    } else {
        CHECKMIRAVERSION(support_file_path)
        mira_version_ch = CHECKMIRAVERSION.out.view()
    }

    //creating platform value
    if (params.e == 'Flu-Illumina') {
        platform = 'illumina'
    } else if (params.e == 'SC2-Whole-Genome-Illumina') {
        platform = 'illumina'
    } else if (params.e == 'RSV-Illumina') {
        platform = 'illumina'
    } else if (params.e == 'Flu-ONT') {
        platform = 'ont'
    } else if (params.e == 'SC2-Spike-Only-ONT') {
        platform = 'ont'
    } else if (params.e == 'SC2-Whole-Genome-ONT') {
        platform = 'ont'
    } else if (params.e == 'RSV-ONT') {
        platform = 'ont'
    }

    //creating virus value
    if (params.e == 'Flu-Illumina') {
        virus = 'flu'
    } else if (params.e == 'SC2-Whole-Genome-Illumina') {
        virus = 'sc2-wgs'
    } else if (params.e == 'RSV-Illumina') {
        virus = 'rsv'
    } else if (params.e == 'Flu-ONT') {
        virus = 'flu'
    } else if (params.e == 'SC2-Spike-Only-ONT') {
        virus = 'sc2-spike'
    } else if (params.e == 'SC2-Whole-Genome-ONT') {
        virus = 'sc2-wgs'
    } else if (params.e == 'RSV-ONT') {
        virus = 'rsv'
    }

    //getting config type for the MIRA summary file
    if (params.custom_irma_config == null) {
        if (params.irma_module == 'none') {
            irma_config_type_ch = 'default-config'
        } else {
            irma_config_type_ch = params.irma_module + '-config'
        }
    } else {
        irma_config_type_ch = 'custom-config'
    }
    //getting path to qc_pass_fail_settings.yml
    if (params.custom_qc_settings == null && params.sourcepath == null) {
        qc_path_ch = "${projectDir}/bin/irma_config/qc_pass_fail_settings.yaml"
    } else if (params.custom_qc_settings == null && params.sourcepath != null) {
        qc_path_ch = "${params.sourcepath}/bin/irma_config/qc_pass_fail_settings.yaml"
        } else {
            qc_path_ch = params.custom_qc_settings
    }

    //create aggregate reports with or without parquet files
    if (params.reformat_tables == true) {
    PREPAREMIRAREPORTSWITHPARQ(dais_outputs_ch, support_file_path, irma_dir_ch, samplesheet_ch, qc_path_ch, platform, virus, irma_config_type_ch, runid)
    ch_versions = ch_versions.mix(PREPAREMIRAREPORTSWITHPARQ.out.versions)
    } else {
    PREPAREMIRAREPORTS(dais_outputs_ch, support_file_path, irma_dir_ch, samplesheet_ch, qc_path_ch, platform, virus, irma_config_type_ch, runid)
    ch_versions = ch_versions.mix(PREPAREMIRAREPORTS.out.versions)
    }

    //collate versions
    versions_path_ch = ch_versions.distinct().collectFile(name: 'collated_versions.yml')
    versions_path_ch.view()

    emit:
    collated_versions = versions_path_ch                     // channel: [ versions.yml ]
    mira_version_ch                                 // channel:specifies if MIRA-NF version is up to date
}
