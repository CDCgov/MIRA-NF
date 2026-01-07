/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NEXTCLADE {

    take:
    summary_ch   // channel: holds aggregate summary report
    amended_consensus_ch  // channel: holds amended consensus fasta file

    main:
    ch_versions = Channel.empty()

    // Extracting subtype information from summary report and assigning a nextclade dataset based on subtype
    // Flu handling
    if (params.e == 'Flu-Illumina' || params.e == 'Flu-ONT') {
       nextclade_ch = summary_ch
        .splitCsv(header: true)
        .map { row ->
       def dataset = null

            // Determine dataset based on reference and subtype
            if (row.reference =~ /HA/) {
                if (row.subtype in ['H1N1', 'H1']) {
                    dataset = 'influenza-a-h1n1pdm-ha'
                } else if (row.subtype in ['H3N2', 'H3']) {
                    dataset = 'influenza-a-h3n2-ha'
                } else if (row.subtype in ['BVIC']) {
                    dataset = 'influenza-b-victoria-ha'
                }
            } else if (row.reference =~ /NA/) {
                if (row.subtype in ['H1N1', 'N1']) {
                    dataset = 'influenza-a-h1n1pdm-na'
                } else if (row.subtype in ['H3N2', 'N2']) {
                    dataset = 'influenza-a-h3n2-na'
                } else if (row.subtype in ['BVIC']) {
                    dataset = 'influenza-b-victoria-na'
                }
            }
            // Return a map with the new nextclade_dataset field
            [
                sample_id: row.sample_id,
                reference: row.reference,
                subtype:   row.subtype,
                nextclade_dataset: dataset
            ]
        }
        // Filter only rows where reference is HA or NA AND nextclade_dataset is assigned
        .filter { row ->
            (row.reference =~ /HA|NA/) && (row.nextclade_dataset != null)
        }
    } else if (params.e == 'RSV-Illumina' || params.e == 'RSV-ONT') {
        // RSV handling
        nextclade_ch = summary_ch
        .splitCsv(header: true)
        .map { row ->
            def dataset = null

            // Determine dataset based on RSV subtype
            if (row.subtype in ['RSV_AD']) {
                dataset = 'rsv-a'
            } else if (row.subtype in ['RSV_BD']) {
                dataset = 'rsv-b'
            }

            [
                sample_id: row.sample_id,
                reference: row.reference,
                subtype:   row.subtype,
                nextclade_dataset: dataset
            ]
        }
        // Filter only rows where nextclade_dataset is assigned
        .filter { row ->
            row.nextclade_dataset != null
        }

    } else {
    // SARS-CoV-2 handling
    nextclade_ch = summary_ch
    .splitCsv(header: true)
    .map { row ->
        // Assign dataset only if subtype is SARS-CoV-2
        def dataset = (row.subtype == 'SARS-CoV-2') ? 'sars-cov-2' : null
        [
            sample_id: row.sample_id,
            reference: row.reference,
            subtype:   row.subtype,
            nextclade_dataset: dataset
        ]
    }
    // Keep only rows that have a dataset assigned
    .filter { row -> row.nextclade_dataset != null }
    }
    nextclade_ch.view()

    // TODO nf-core: substitute modules here for the modules of your subworkflow

    emit:
    // TODO nf-core: edit emitted channels

    versions = ch_versions                     // channel: [ versions.yml ]
}
