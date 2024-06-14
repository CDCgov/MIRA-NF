process FINDCHEMISTRYI {
    tag 'finding chemistry parameters for '
    label 'process_single'
    publishDir "${params.outdir}/IRMA", pattern: '*.csv', mode: 'copy'

    input:
    tuple val(sample), path(fastq), path(runid)

    output:
    path "${sample}_chemistry.csv", emit: sample_chem_csv
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${launchDir}/bin/find_chemistry_i.py -s "${sample}" -q "${fastq}" -r "${runid}" -e "${params.e}" -p "${launchDir}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        findchemistryi: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        findchemistryi: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """
}
