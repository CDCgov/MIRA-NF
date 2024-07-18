#!/bin/bash
#$ -o nextflow.$JOB_ID.out
#$ -e nextflow.$JOB_ID.err
#$ -N nf-mira-cli
#$ -pe smp 4
#$ -l h_rt=72:00:00
#$ -l h_vmem=32G
#$ -q all.q
#$ -cwd
#$ -V

usage() {
	echo -e "Usage in git cloned CLI: \n bash $0 -d <pth_to_mira-cli> -i <path_to_samplesheet.csv> -o <outdir> -r <run_id> -e <experiment_type> -f <nextflow_profiles> <OPTIONAL: -p amplicon_library> <optional: -q processing_q> <optional: -m email_address> <optional: -n > " 1>&2
	exit 1
}

# Experiment type options: Flu-ONT, SC2-Spike-Only-ONT, Flu_Illumina, SC2-Whole-Genome-ONT, SC2-Whole-Genome-Illumina
# Primer Schema options: articv3, articv4, articv4.1, articv5.3.2, qiagen, swift, swift_211206

while getopts 'd:i:o:r:e:p:f:q:m:na' OPTION; do
	case "$OPTION" in
	d) DIRNAME="$OPTARG" ;;
	i) INPUT="$OPTARG" ;;
	o) OUTPATH="$OPTARG" ;;
	r) RUNPATH="$OPTARG" ;;
	e) EXPERIMENT_TYPE="$OPTARG" ;;
	p) PRIMER_SCHEMA="$OPTARG" ;;
	f) APPLICATION="$OPTARG" ;;
	q) PROCESSQ="$OPTARG" ;;
	m) EMAIL="$OPTARG" ;;
	*) usage ;;
	esac
done
source /etc/profile
TAR=True

# Archive previous run using the summary.xlsx file sent in email
if [ -d "$1/dash-json/" ] && [ -n "${TAR}" ]; then
	tar --remove-files -czf ${RUNPATH}/previous_run_$(date -d @$(stat -c %Y ${RUNPATH}/dash-json/) "+%Y%b%d-%H%M%S").tar.gz ${RUNPATH}/*html ${RUNPATH}/*fasta ${RUNPATH}/*txt ${RUNPATH}/*xlsx ${RUNPATH}/IRMA ${RUNPATH}/dash-json
fi

# Run nextflow
module load nextflow/23.10.0
nextflow run "$DIRNAME"/mira-cli/main.nf \
	--input "$INPUT" \
	--outdir "$OUTPATH" \
	--runpath "$RUNPATH" \
	--e "$EXPERIMENT_TYPE" \
	--p "$PRIMER_SCHEMA" \
	--process_q "$PROCESSQ" \
	-profile "$APPLICATION" \
	--email "$EMAIL"
