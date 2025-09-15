###This is a template script to run the MIRA-NF pipeline on an SGE HPC system.###
### The user needs to modify the paths and parameters before running.###
### The hpc parameters (e.g. memory, runtime, queue) also need be adjusted to the usesr's hpc.###
#!/bin/bash
#$ -o nextflow.$JOB_ID.out
#$ -e nextflow.$JOB_ID.err
#$ -N MIRA-NF
#$ -pe smp 4
#$ -l h_rt=72:00:00
#$ -l h_vmem=128G
#$ -q flu.q
#$ -cwd
#$ -V

#Load nextflow module
module load nextflow/24.10.4

##Abosolute file paths are needed to run the pipeline
# Run nextflow
nextflow run ./main.nf \
   -profile singularity,sge \
   --input <RUN_PATH>/samplesheet.csv \
   --outdir <OUTDIR_PATH> \
   --runpath <RUN_PATH> \
   --e <EXPERIMENT_TYPE> \
   --p <PRIMER_SET> (optional) \
   --subsample_reads <READ_COUNT> (optional)\
   --reformat_tables true (optional) \
   --read_qc false (optional) \

## There are more flag that can be used to customize the run, please see the readme for more details.
