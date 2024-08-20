#!/bin/bash
#$ -o nextflow.$JOB_ID.out
#$ -e nextflow.$JOB_ID.err
#$ -N nf-mira-cli
#$ -pe smp 4
#$ -l h_rt=72:00:00
#$ -l h_vmem=32G
#$ -q long.q
#$ -cwd
#$ -V

usage() {
	echo -e "Usage in git cloned CLI: \n bash $0 -d <pth_to_mira-cli> -i <path_to_samplesheet.csv> -o <outdir> -r <run_id> -e <experiment_type> -f <nextflow_profiles> <optional: -p amplicon_library> <optional: -g custom_amplicon_library> <optional: -a parquet_files> <optional: -c read_counts> <optional: -q processing_q> <optional: -m email_address> <optional: -b irma_config> <optional: -n > " 1>&2
	exit 1
}

# Experiment type options: Flu-ONT, SC2-Spike-Only-ONT, Flu_Illumina, SC2-Whole-Genome-ONT, SC2-Whole-Genome-Illumina
# Primer Schema options: articv3, articv4, articv4.1, articv5.3.2, qiagen, swift, swift_211206

while getopts 'd:i:o:r:e:p:g:f:a:c:q:m:b:na' OPTION; do
	case "$OPTION" in
	d) DIRNAME="$OPTARG" ;;
	i) INPUT="$OPTARG" ;;
	o) OUTPATH="$OPTARG" ;;
	r) RUNPATH="$OPTARG" ;;
	e) EXPERIMENT_TYPE="$OPTARG" ;;
	p) PRIMER_SCHEMA="$OPTARG" ;;
	g) CUSTOM_PRIMERS="$OPTARG" ;;
	f) APPLICATION="$OPTARG" ;;
	a) PARQUET="$OPTARG" ;;
	c) READ_COUNTS="$OPTARG" ;;
	q) PROCESSQ="$OPTARG" ;;
	m) EMAIL="$OPTARG" ;;
	b) OTHER_IRMA_CONFIG="$OPTARG" ;;
	*) usage ;;
	esac
done
source /etc/profile
TAR=True

if [[ -z "${DIRNAME}" ]] || [ -z "${INPUT}" ] || [ -z "${OUTPATH}" ] || [ -z "${RUNPATH}" ] || [ -z "${EXPERIMENT_TYPE}" ] || [ -z "${PROCESSQ}" ] || [ -z "${APPLICATION}" ]; then
	usage
fi

if [[ -z "${PRIMER_SCHEMA}" ]]; then
	OPTIONALARGS1=""
else
	OPTIONALARGS1="--p $PRIMER_SCHEMA"
fi

if [[ -z "${CUSTOM_PRIMERS}" ]]; then
	OPTIONALARGS2=""
else
	OPTIONALARGS2="--custom_primers $CUSTOM_PRIMERS"
fi

if [[ -z "${PARQUET}" ]]; then
	OPTIONALARGS3=""
else
	OPTIONALARGS3="--parquet_files $PARQUET"
fi

if [[ -z "${READ_COUNTS}" ]]; then
	OPTIONALARGS4=""
else
	OPTIONALARGS4="--subsample_reads $READ_COUNTS"
fi

if [[ -z "${OTHER_IRMA_CONFIG}" ]]; then
	OPTIONALARGS5=""
else
	OPTIONALARGS5="--irma_config $OTHER_IRMA_CONFIG"
fi

if [[ -z "${EMAIL}" ]]; then
	OPTIONALARGS6=""
else
	OPTIONALARGS6="--email $EMAIL"
fi

# Archive previous run using the summary.xlsx file sent in email
if [ -d "$1/dash-json/" ] && [ -n "${TAR}" ]; then
	tar --remove-files -czf ${RUNPATH}/previous_run_$(date -d @$(stat -c %Y ${RUNPATH}/dash-json/) "+%Y%b%d-%H%M%S").tar.gz ${RUNPATH}/*html ${RUNPATH}/*fasta ${RUNPATH}/*txt ${RUNPATH}/*xlsx ${RUNPATH}/IRMA ${RUNPATH}/dash-json
fi

# Run nextflow
module load nextflow/23.10.0
nextflow run "$DIRNAME"/mira-nf/main.nf \
	--input "$INPUT" \
	--outdir "$OUTPATH" \
	--runpath "$RUNPATH" \
	--e "$EXPERIMENT_TYPE" \
	--process_q "$PROCESSQ" \
	-profile "$APPLICATION" \
	$OPTIONALARGS1 \
	$OPTIONALARGS2 \
	$OPTIONALARGS3 \
	$OPTIONALARGS4 \
	$OPTIONALARGS5 \
	$OPTIONALARGS6
