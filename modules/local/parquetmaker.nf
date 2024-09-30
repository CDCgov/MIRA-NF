process PARQUETMAKER {
    tag { 'Creating paquet output' }
    label 'process_low'

    container 'cdcgov/mira-nf:latest'

    input:
    path(html_outputs)
    val run_path
    val samplesheet

    output:
    path('*'), emit: summary_parq
    path 'versions.yml' , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def run_name = run_path.getBaseName()

    """
    if [[ -f  MIRA_${run_name}_failed_amended_consensus.fasta && -f MIRA_${run_name}_amended_consensus.fasta ]]; then
    cat MIRA_${run_name}_amended_consensus.fasta MIRA_${run_name}_failed_amended_consensus.fasta > nt.fasta
    fi
    if [[ ! -f  MIRA_${run_name}_failed_amended_consensus.fasta && -f MIRA_${run_name}_amended_consensus.fasta ]]; then
    cat MIRA_${run_name}_amended_consensus.fasta > nt.fasta
    fi
    if [[ -f  MIRA_${run_name}_failed_amended_consensus.fasta && ! -f MIRA_${run_name}_amended_consensus.fasta ]]; then
    cat MIRA_${run_name}_failed_amended_consensus.fasta > nt.fasta
    fi
    if [[ -f  MIRA_${run_name}_failed_amino_acid_consensus.fasta && -f  MIRA_${run_name}_amino_acid_consensus.fasta ]]; then
    cat MIRA_${run_name}_amino_acid_consensus.fasta MIRA_${run_name}_amino_acid_consensus.fasta > aa.fasta
    fi
    if [[ ! -f  MIRA_${run_name}_failed_amino_acid_consensus.fasta && -f MIRA_${run_name}_amino_acid_consensus.fasta ]]; then
    cat MIRA_${run_name}_amino_acid_consensus.fasta > aa.fasta
    fi
    if [[ -f  MIRA_${run_name}_failed_amino_acid_consensus.fasta && ! -f MIRA_${run_name}_amino_acid_consensus.fasta ]]; then
    cat MIRA_${run_name}_failed_amino_acid_consensus.fasta > aa.fasta
    fi
    python3 ${projectDir}/bin/parquet_maker.py -f nt.fasta -o ${run_name}_amended_consensus.parq -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f aa.fasta -o ${run_name}_amino_acid_consensus.parq -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f ${samplesheet} -o ${run_name}_samplesheet.parq -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f *minorindels.xlsx -o ${run_name}_indels.parq -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f *minorvariants.xlsx -o ${run_name}_variants.parq -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f *summary.xlsx -o ${run_name}_summary.parq -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -p ${params.outdir} -r ${run_name}
    cat ${params.outdir}/*/IRMA/*/logs/run_info.txt > run_info_setup.txt
    head -n 65 run_info_setup.txt > run_info.txt
    python3 ${projectDir}/bin/parquet_maker.py -f run_info.txt -o ${run_name}_irma_config.parq -r ${run_name}

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
