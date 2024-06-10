/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMTOOLS_SORT      } from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX     } from '../../../modules/nf-core/samtools/index/main'

workflow CHECKIRMA {
    take:
    irma_output_ch

    main:

    ch_versions = Channel.empty()

    // Irma checkpoint
    check_irma_ch = IRMA.out.map { item ->
        def sample = item[0]
        def paths = item[1]
        def directory = paths.find { it.endsWith(sample) && !it.endsWith('.log') }
        return tuple(sample, directory)
    }
    check_irma(check_irma_ch)

    // Filter samples to passed and failed
    passedSamples = check_irma.out.filter { it[2].text.trim() == 'passed' }.map { it[1] }
    failedSamples = check_irma.out.filter { it[2].text.trim() == 'failed' }.map { it[0] }

    passedSamples_files_ch = passedSamples.collect().flatten()
    passedSamples_files_ch.view()

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}

