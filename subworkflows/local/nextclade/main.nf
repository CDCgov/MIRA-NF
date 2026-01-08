/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { GETNEXTCLADEDATASET     } from '../../../modules/local/getnextcladedataset'

workflow NEXTCLADE {

    take:
    summary_ch   // channel: holds aggregate summary report
    nextclade_fasta_files_ch  // channel: holds amended consensus fasta file

    main:
    ch_versions = Channel.empty()

    // List of expected nextclade FASTA filenames (without path)
    def expected_fastas = [
        "influenza-a-h3n2-ha",
        "influenza-a-h1n1pdm-ha",
        "influenza-b-victoria-ha",
        "influenza-a-h1n1pdm-na",
        "influenza-a-h3n2-na",
        "influenza-b-victoria-na",
        "rsv-a",
        "rsv-b",
        "sars-cov-2"
    ]

    // Assume channel carrying paths to generated FASTAs
    nextclade_fasta_files_ch
        .flatten()
        .map { fasta_path ->
            // Ensure this is a Path object
            def path_obj = fasta_path as Path

            // Extract filename without directory and extension
            def base_name = path_obj.getName().replaceFirst(/\.fasta$/, '')

            // Match against expected datasets
            def dataset_name = expected_fastas.find { base_name.contains(it) }

            if (dataset_name) {
                tuple(path_obj, dataset_name)
            } else {
                null
            }
        }
        .filter { it != null }
        .set { nextclade_dataset_ch }

        nextclade_dataset_ch.view()

    // TODO nf-core: substitute modules here for the modules of your subworkflow

    emit:
    // TODO nf-core: edit emitted channels

    versions = ch_versions                     // channel: [ versions.yml ]
}
