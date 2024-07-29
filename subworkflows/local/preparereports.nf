/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PREPAREIRMAJSON   } from '../../modules/local/prepareirmajson'
include { STATICHTML        } from '../../modules/local/statichtml'
include { PARQUETMAKER      } from '../../modules/local/parquetmaker'
include { PREPEMAIL         } from '../../modules/local/prepemail'

workflow PREPAREREPORTS {
    take:
    dais_outputs_ch // channel: holds dais outputs
    ch_versions // channel: holds all previous version

    main:
    platform = Channel.empty()
    virus = Channel.empty()
    run_ID_ch = Channel.fromPath(params.runpath, checkIfExists: true)

    //creating platform value
    if (params.e == 'Flu-Illumina') {
        platform = 'illumina'
    } else if (params.e == 'SC2-Whole-Genome-Illumina') {
        platform = 'illumina'
    } else if (params.e == 'Flu-ONT') {
        platform = 'ont'
    } else if (params.e == 'SC2-Spike-Only-ONT') {
        platform = 'ont'
    } else if (params.e == 'SC2-Whole-Genome-ONT') {
        platform = 'ont'
    }

    //creating virus value
    if (params.e == 'Flu-Illumina') {
        virus = 'flu'
    } else if (params.e == 'Flu-ONT') {
        virus = 'flu'
    } else if (params.e == 'SC2-Spike-Only-ONT') {
        virus = 'sc2-spike'
    } else if (params.e == 'SC2-Whole-Genome-ONT') {
        virus = 'sc2'
    } else if (params.e == 'SC2-Whole-Genome-Illumina') {
        virus = 'sc2'
    }

    //
    PREPAREIRMAJSON(dais_outputs_ch, platform, virus)
    ch_versions = ch_versions.mix(PREPAREIRMAJSON.out.versions)

    STATICHTML(PREPAREIRMAJSON.out.dash_json, run_ID_ch)
    ch_versions = ch_versions.mix(STATICHTML.out.versions)

    if (params.parquet_files == true) {
        PARQUETMAKER(STATICHTML.out.html, run_ID_ch, params.input)
        ch_versions = ch_versions.mix(PARQUETMAKER.out.versions)

        versions_path_ch = ch_versions.distinct().collectFile(name: 'collated_versions.yml')
        PREPEMAIL(PARQUETMAKER.out.summary_parq, versions_path_ch)
    } else if (params.parquet_files == false) {
        versions_path_ch = ch_versions.distinct().collectFile(name: 'collated_versions.yml')
        PREPEMAIL(STATICHTML.out.html, versions_path_ch)
    }

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}
