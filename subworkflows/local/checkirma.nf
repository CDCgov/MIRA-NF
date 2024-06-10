/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CONFIRMIRMAOUTPUT  } from "${launchDir}/modules/local/confirmirmaoutput"
include { CREATEDAISINPUT    } from "${launchDir}/modules/local/createdaisinput"

workflow CHECKIRMA {
    take:
    irma_output_ch

    main:

    ch_versions = Channel.empty()

    // Irma checkpoint
    check_irma_ch = irma_output_ch.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    CONFIRMIRMAOUTPUT(check_irma_ch)

    // Filter samples to passed and failed
    passedSamples = CONFIRMIRMAOUTPUT.out.filter { it[2].text.trim() == 'passed' }.map { it[1] }
    failedSamples = CONFIRMIRMAOUTPUT.out.filter { it[2].text.trim() == 'failed' }.map { it[0] }

    //concat files for daisinput and print file to working directory for troubleshooting
    CREATEDAISINPUT(passedSamples.colltect())

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}

