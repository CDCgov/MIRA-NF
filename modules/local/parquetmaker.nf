process PARQUETMAKER {
    label 'process_low'

    container 'cdcgov/mira-nf:python3.10-alpine'

    input:
    path(html_outputs)
    path run_path
    path samplesheet
    val instrument
    path outdir

    output:
    path('*.{parq,csv}'), emit: summary_parq
    path 'versions.yml' , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def run_name = run_path.getBaseName()

    """
    ## This logic is very specific to the MIRA pipeline and should not be changed.
    ## If aa.fast and nt.fast is not being created then something it broken up stream that needs to be fixed
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

    parquet_maker.py -f nt.fasta -o ${run_name}_amended_consensus -r ${run_name} -i ${instrument}
    parquet_maker.py -f aa.fasta -o ${run_name}_amino_acid_consensus -r ${run_name} -i ${instrument}
    parquet_maker.py -f ${samplesheet} -o ${run_name}_samplesheet -r ${run_name} -i ${instrument}
    parquet_maker.py -f *minorindels.xlsx -o ${run_name}_indels -r ${run_name} -i ${instrument}
    parquet_maker.py -f *minorvariants.xlsx -o ${run_name}_variants -r ${run_name} -i ${instrument}
    parquet_maker.py -f *summary.xlsx -o ${run_name}_summary -r ${run_name} -i ${instrument}
    parquet_maker.py -p ${outdir} -r ${run_name} -i ${instrument}
    cat ${outdir}/*/IRMA/*/logs/run_info.txt > run_info_setup.txt
    head -n 65 run_info_setup.txt > run_info.txt
    parquet_maker.py -f run_info.txt -o ${run_name}_irma_config -r ${run_name} -i ${instrument}

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
