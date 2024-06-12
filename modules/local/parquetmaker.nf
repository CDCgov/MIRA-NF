process PARQUETMAKER {
    tag { 'Creating paquet output' }
    label 'process_low'
    container 'cdcgov/spyne-dev:v1.2.0'

    publishDir "${params.outdir}/parq_files", pattern: '*.parq',  mode: 'copy'

    input:
    val x
    val run_path

    output:
    path('*'), emit: summary_parq
    path 'versions.yml' , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def run_name = run_path.getBaseName()

    """
    if [ -f  ${params.outdir}/failed_amended_consensus.fasta ]; then
    cat ${params.outdir}/MIRA_${run_name}_amended_consensus.fasta ${params.outdir}/MIRA_${run_name}_failed_amended_consensus.fasta > nt.fasta
    fi
    if [ ! -f  ${params.outdir}/failed_amended_consensus.fasta ]; then
    cat ${params.outdir}/MIRA_${run_name}_amended_consensus.fasta > nt.fasta
    fi
    if [ -f  ${params.outdir}/failed_amino_acid_consensus.fasta ]; then
    cat ${params.outdir}/MIRA_${run_name}_amino_acid_consensus.fasta ${params.outdir}/MIRA_${run_name}_amino_acid_consensus.fasta > aa.fasta
    fi
    if [ ! -f  ${params.outdir}/failed_amino_acid_consensus.fasta ]; then
    cat ${params.outdir}/MIRA_${run_name}_amino_acid_consensus.fasta > aa.fasta
    fi
    python3 ${launchDir}/bin/parquet_maker.py -f nt.fasta -o ${run_name}_amended_consensus.parq -r ${run_name}
    python3 ${launchDir}/bin/parquet_maker.py -f aa.fasta -o ${run_name}_amino_acid_consensus.parq -r ${run_name}
    python3 ${launchDir}/bin/parquet_maker.py -f ${params.outdir}/samplesheet.csv -o ${run_name}_samplesheet.parq -r ${run_name}
    python3 ${launchDir}/bin/parquet_maker.py -f ${params.outdir}/*minorindels.xlsx -o ${run_name}_indels.parq -r ${run_name}
    python3 ${launchDir}/bin/parquet_maker.py -f ${params.outdir}/*minorvariants.xlsx -o ${run_name}_variants.parq -r ${run_name}
    python3 ${launchDir}/bin/parquet_maker.py -f ${params.outdir}/*summary.xlsx -o ${run_name}_summary.parq -r ${run_name}
    python3 ${launchDir}/bin/parquet_maker.py -p ${params.outdir} -r ${run_name}
    cat ${params.outdir}/IRMA/*/logs/run_info.txt > run_info_setup.txt
    head -n 65 run_info_setup.txt > run_info.txt
    python3 ${launchDir}/bin/parquet_maker.py -f run_info.txt -o ${run_name}_irma_config.parq -r ${run_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parquetmaker: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """

    stub:
    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parquetmaker: \$(python3 --version |& sed '1!d ; s/python3 //')
    END_VERSIONS
    """
}
