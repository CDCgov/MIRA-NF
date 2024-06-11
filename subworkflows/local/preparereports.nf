/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PREPAREIRMAJSON   } from "${launchDir}/modules/local/prepareirmajson"
include { STATICHTML        } from "${launchDir}/modules/local/statichtml"
include { PARQUETMAKER      } from "${launchDir}/modules/local/parquetmaker"
include { PREPEMAIL         } from "${launchDir}/modules/local/prepemail"

workflow PREPAREREPORTS {
    take:
    dais_outputs_ch

    main:
    platform = Channel.empty()
    virus = Channel.empty()
    run_ID_ch = Channel.fromPath(params.outdir, checkIfExists: true)
    ch_versions = Channel.empty()

    //creating platform value
    if (params.e == 'Flu_Illumina' || 'SC2-Whole-Genome-Illumina') {
        platform = 'illumina'
    } else if (params.e == 'Flu-ONT' || 'SC2-Spike-Only-ONT' || 'SC2-Whole-Genome-ONT') {
        platform = 'ont'
    }

    //creating virus value
    if (params.e == 'Flu_Illumina' || 'Flu-ONT') {
        virus = 'flu'
    } else if (params.e == 'SC2-Spike-Only-ONT' || 'SC2-Whole-Genome-ONT' || 'SC2-Whole-Genome-Illumina') {
        virus = 'sc2'
    }

    PREPAREIRMAJSON(dais_outputs_ch, platform, virus)
    ch_versions = ch_versions.mix(PREPAREIRMAJSON.out.versions)

    STATICHTML(PREPAREIRMAJSON.out.dash_json)
    ch_versions = ch_versions.mix(STATICHTML.out.versions)

    PARQUETMAKER(STATICHTML.out.html, run_ID_ch)
    ch_versions = ch_versions.mix(PARQUETMAKER.out.versions)

    PREPEMAIL(PARQUETMAKER.out.summary_parq)

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}
