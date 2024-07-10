/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CONFIRMIRMAOUTPUT  } from '../../modules/local/confirmirmaoutput'
include { PASSFAILED         } from '../../modules/local/passfailed'
include { CREATEDAISINPUT    } from '../../modules/local/createdaisinput'

workflow CHECKIRMA {
    take:
    check_irma_ch

    main:

    //IRMA checkpoint
    CONFIRMIRMAOUTPUT(check_irma_ch)

    // Filter samples to passed and failed
    passedSamples = CONFIRMIRMAOUTPUT.out.filter { it[2].text.trim() == 'passed' }.map { it[1] }
    failedSamples = CONFIRMIRMAOUTPUT.out.filter { it[2].text.trim() == 'failed' }.map { it[0] }

    //moving failed to IRMA_negative folder
    PASSFAILED(failedSamples)

    //concat files for daisinput and print file to working directory for troubleshooting
    dais_ch = CREATEDAISINPUT(passedSamples.collect())

    emit:
    dais_ch                    // channel: paths to dais inputs
}

