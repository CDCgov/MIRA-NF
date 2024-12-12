/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PREPAREIRMAJSON   } from '../../modules/local/prepareirmajson'
include { STATICHTML        } from '../../modules/local/statichtml'
include { PARQUETMAKER      } from '../../modules/local/parquetmaker'

workflow PREPAREREPORTS {
    take:
    dais_outputs_ch // channel: holds dais outputs
    nf_samplesheet_ch //channel: hold the nextflow samplesheet
    ch_versions // channel: holds all previous version

    main:
    platform = Channel.empty()
    virus = Channel.empty()
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)
    irma_dir_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    //If sourcepath flag is given, then it will use the sourcepath to point to the reference files and support files in prepareIRMAjson and staticHTML
    if (params.sourcepath == 'none') {
        support_file_path = Channel.fromPath(projectDir, checkIfExists: true)
    } else {
        support_file_path = Channel.fromPath(params.sourcepath, checkIfExists: true)
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
        virus = 'sc2'
    } else if (params.e == 'RSV-Illumina') {
        virus = 'rsv'
    } else if (params.e == 'Flu-ONT') {
        virus = 'flu'
    } else if (params.e == 'SC2-Spike-Only-ONT') {
        virus = 'sc2-spike'
    } else if (params.e == 'SC2-Whole-Genome-ONT') {
        virus = 'sc2'
    } else if (params.e == 'RSV-ONT') {
        virus = 'rsv'
    }

    //if custom irma congif used use custom in irma_config params
    //This will be used in the find_chemisrty module
    if (params.custom_irma_config == '/none/') {
        if (params.irma_config == 'none') {
            irma_config_type_ch = 'default-config'
        } else {
            irma_config_type_ch = params.irma_config + '-config'
        }
    } else {
        irma_config_type_ch = 'custom-config'
    }
    //getting path to qc_pass_fail_settings.yml
    if (params.custom_qc_settings == '/none/' && params.sourcepath == 'none') {
        qc_path_ch = "${projectDir}/bin/irma_config/qc_pass_fail_settings.yaml"
    } else if (params.custom_qc_settings == '/none/' && params.sourcepath != 'none') {
        qc_path_ch = "${params.sourcepath}/bin/irma_config/qc_pass_fail_settings.yaml"
        } else {
            qc_path_ch = params.custom_qc_settings
    }

    println qc_path_ch

    //create aggregate reports
    PREPAREIRMAJSON(dais_outputs_ch, support_file_path, irma_dir_ch, nf_samplesheet_ch, platform, virus, irma_config_type_ch, qc_path_ch)
    ch_versions = ch_versions.mix(PREPAREIRMAJSON.out.versions)

    //convert aggragate reports (json files) into html files
    STATICHTML(support_file_path, PREPAREIRMAJSON.out.dash_json_and_fastqs, run_ID_ch)
    ch_versions = ch_versions.mix(STATICHTML.out.versions)

    //Parquet amker converts the report tables into csv files and parquet files
    if (params.reformat_tables == true) {
        PARQUETMAKER(STATICHTML.out.reports, run_ID_ch, params.input)
        ch_versions = ch_versions.mix(PARQUETMAKER.out.versions)

        versions_path_ch = ch_versions.distinct().collectFile(name: 'collated_versions.yml')
    } else if (params.reformat_tables == false) {
        versions_path_ch = ch_versions.distinct().collectFile(name: 'collated_versions.yml')
    }

    versions_path_ch.view()

    emit:
    collated_versions = versions_path_ch                     // channel: [ versions.yml ]
}
