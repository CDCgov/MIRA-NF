process PARQUETMAKER {
    label 'process_low'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path(html_outputs)
    val run_path
    path samplesheet

    output:
    path('*.{parq,csv}'), emit: summary_parq
    path 'versions.yml' , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def run_name = run_path.getBaseName()

    """
    if [[ -f MIRA_${run_name}_failed_amended_consensus.fasta && -f MIRA_${run_name}_amended_consensus.fasta ]]; then
        cat MIRA_${run_name}_amended_consensus.fasta MIRA_${run_name}_failed_amended_consensus.fasta > nt.fasta
    elif [[ -f MIRA_${run_name}_amended_consensus.fasta ]]; then
        cat MIRA_${run_name}_amended_consensus.fasta > nt.fasta
    elif [[ -f MIRA_${run_name}_failed_amended_consensus.fasta ]]; then
        cat MIRA_${run_name}_failed_amended_consensus.fasta > nt.fasta
    else
        touch nt.fasta  # Create an empty nt.fasta if neither file exists
    fi
    if [[ -f MIRA_${run_name}_failed_amino_acid_consensus.fasta && -f MIRA_${run_name}_amino_acid_consensus.fasta ]]; then
         MIRA_${run_name}_amino_acid_consensus.fasta MIRA_${run_name}_failed_amino_acid_consensus.fasta > aa.fasta
    elif [[ -f MIRA_${run_name}_amino_acid_consensus.fasta ]]; then
        cat MIRA_${run_name}_amino_acid_consensus.fasta > aa.fasta
    elif [[ -f MIRA_${run_name}_failed_amino_acid_consensus.fasta ]]; then
        cat MIRA_${run_name}_failed_amino_acid_consensus.fasta > aa.fasta
    else
        touch aa.fasta  # Create an empty aa.fasta if neither file exists
    fi

    python3 ${projectDir}/bin/parquet_maker.py -f nt.fasta -o ${run_name}_amended_consensus -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f aa.fasta -o ${run_name}_amino_acid_consensus -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f ${samplesheet} -o ${run_name}_samplesheet -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f *minorindels.xlsx -o ${run_name}_indels -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f *minorvariants.xlsx -o ${run_name}_variants -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -f *summary.xlsx -o ${run_name}_summary -r ${run_name}
    python3 ${projectDir}/bin/parquet_maker.py -p ${params.outdir} -r ${run_name}
    cat ${params.outdir}/*/IRMA/*/logs/run_info.txt > run_info_setup.txt
    head -n 65 run_info_setup.txt > run_info.txt
    python3 ${projectDir}/bin/parquet_maker.py -f run_info.txt -o ${run_name}_irma_config -r ${run_name}

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
