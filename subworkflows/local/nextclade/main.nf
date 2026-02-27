/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { GETNEXTCLADEDATASET } from "../../../modules/local/getnextcladedataset/main"
include { RUNNEXTCLADE } from "../../../modules/local/runnextclade/main"
include { UPDATEMIRASUMMARY } from "../../../modules/local/updatemirasummary/main"

workflow NEXTCLADE {
    take:
    nextclade_fasta_files_ch // channel: holds amended consensus fasta file
    summary_ch // channel: holds summary information
    virus // value: virus type
    runid // value: run id
    ch_versions // channel: holds all previous version

    main:

    // List of expected nextclade FASTA filenames (without path)
    def expected_fastas = [
        "flu_h3n2_ha",
        "flu_h1n1pdm_ha",
        "flu_vic_ha",
        "flu_h3n2_na",
        "flu_h1n1pdm_na",
        "flu_vic_na",
        "rsv_a",
        "rsv_b",
        "sars-cov-2",
    ]

    // Most recent Nextclade dataset tags
    def nextclade_tags = [
        "flu_h3n2_ha": "2026-01-14--19-24-43Z",
        "flu_h1n1pdm_ha": "2026-01-14--19-24-43Z",
        "flu_vic_ha": "2025-10-22--18-11-36Z",
        "flu_h3n2_na": "2026-01-14--08-53-00Z",
        "flu_h1n1pdm_na": "2026-01-14--08-53-00Z",
        "flu_vic_na": "2025-09-09--12-13-13Z",
        "rsv_a": "2025-09-09--12-13-13Z",
        "rsv_b": "2025-09-09--12-13-13Z",
        "sars-cov-2": "2026-01-06--14-59-32Z",
    ]

    // Assume channel carrying paths to generated FASTAs
    nextclade_fasta_files_ch
        .flatten()
        .map { fasta_path ->
            def path_obj = fasta_path as Path
            def base_name = path_obj.getName().replaceFirst(/\.fasta$/, '')

            def dataset_name = expected_fastas.find { base_name.contains(it) }

            if (dataset_name) {
                def tag = nextclade_tags[dataset_name]

                tuple(path_obj, dataset_name, tag)
            }
            else {
                null
            }
        }
        .filter { it != null }
        .set { nextclade_dataset_ch }

    //nextclade_dataset_ch.view()

    GETNEXTCLADEDATASET(nextclade_dataset_ch)
    ch_versions = ch_versions.mix(GETNEXTCLADEDATASET.out.versions)

    RUNNEXTCLADE(GETNEXTCLADEDATASET.out.dataset)
    ch_versions = ch_versions.mix(RUNNEXTCLADE.out.versions)

    // Pass to update summary
    UPDATEMIRASUMMARY(summary_ch, RUNNEXTCLADE.out.tsv.collect(), virus, runid)
    ch_versions = ch_versions.mix(UPDATEMIRASUMMARY.out.versions)


    // collate versions with unique lines into pipeline_info
    versions_path_ch = ch_versions
        .collectFile(
            name: 'collated_versions.yml',
            storeDir: "${params.outdir}/pipeline_info",
        )
        .map { file ->
            def uniqueLines = file.text.readLines().unique().join('\n') + '\n'

            def out = file.parent.resolve('collated_versions.unique.yml')
            out.text = uniqueLines
            return out
        }

    versions_path_ch.view()

    emit:
    versions = ch_versions // channel: [ versions.yml ]
}
