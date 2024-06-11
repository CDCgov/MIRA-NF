process STATICHTML {
    tag 'Creating static HTML output'
    label 'process_single'
    container 'cdcgov/mira:latest'

    publishDir "${params.outdir}", mode: 'copy'

    input:
    val x

    output:
    path("*"), emit: html
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${launchDir}/bin/static_report.py -d ${params.outdir} -l ${launchDir}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        statichtml: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    #Setting up fasta files for parquet maker in later steps
    cat ${params.outdir}/MIRA_*_amended_consensus.fasta > nt.fasta
    cat ${params.outdir}/MIRA_*_amino_acid_consensus.fasta > aa.fasta
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        statichtml: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """
}
