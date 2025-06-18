# mira/nf: Usage

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

**mira-nf/mira** is a bioinformatics pipeline that assembles Influenza genomes, SARS-CoV-2 genomes, the SARS-CoV-2 spike-gene and RSV genomes when given the raw fastq files and a samplesheet. mira-nf/mira can analyze reads from both Illumina and OxFord Nanopore sequencing machines.

MIRA performs these steps for genome assembly and curation:

1. Read QC (optional) ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Present QC for raw reads (optional) ([`MultiQC`](http://multiqc.info/))
3. Checking chemistry in fastq files (optional) ([`python`](https://www.python.org/))
4. Subsampling to faster analysis (optional) ([`bbtools`](https://jgi.doe.gov/data-and-tools/software-tools/bbtools/))
5. Trimming and dapter removal ([`IRMA-core`](https://github.com/CDCgov/irma-core))
6. Genome Assembly ([`IRMA`](https://wonder.cdc.gov/amd/flu/irma/))
7. Annotation of assembly ([`DAIS-ribosome`](https://hub.docker.com/r/cdcgov/dais-ribosome))
8. Collect results from IRMA and DAIS-Ribosome in json files
9. Create html, excel files and amended consensus fasta files
10. Reformat tables into parquet files and csv files

MIRA is able to analyze 7 data types:

1. Flu-Illumina - Flu whole genome data created with an Illumina machine
2. Flu-ONT - Flu whole genome data created with an OxFord Nanoppore machine
3. SC2-Whole-Genome-Illumina - SARS-CoV-2 whole genome data created with an illumina machine
4. SC2-Whole-Genome-ONT - SARS-CoV-2 whole genome data created with an OxFord Nanoppore machine
5. SC2-Spike-Only-ONT - SARS-CoV-2 spike protein data created with an OxFord Nanoppore machine
6. RSV-Illumina - RSV whole genome data created with an Illumina machine
7. RSV-ONT - RSV whole genome data created with an OxFord Nanopore machine

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyze before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

### MIRA samplesheet set up

The sample sheet will need to be set up as seen below. Using the samplesheet that corresponds to the type of data that you are analyzing.

Illumina data should be set up as follows:

```csv
Sample ID,Sample Type
sample_1,Test
sample_2,Test
sample_3,Test
sample_4,Test
```

Each row represents a sample.

| Column    | Description                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Sample ID`  | Custom sample name. This entry must match the name associated with the paired reads. Convert all spaces in sample names to underscores (`_`).                                       |
| `Sample Type` | The sample type for the given sample. Ex: test, - control, + control, etc.                                                                                                         |

**Important things to note about samplesheet:**

- Sample names within the "Sample ID" column need to be unique.
- Be sure that sample names are not nested within another sample name (i.e. having sample_1 and sample_1_1)
- Be sure that there are no empty lines at the end of the samplesheet.
- For Illumina samples be sure that you have read 1 and read 2 for all samples in samplesheet.

ONT data should be set up as follows:

```csv
Barcode #,Sample ID,Sample Type
barcode07,s1,Test
barcode37,s2,Test
barcode41,s3,Test
```

Each row represents a sample.

| Column    | Description                                                                                                                                                                                          |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Barcode #`  | The barcode used to create the ONT data for this sample. Must match the fold contain the fastq files associated with the sample. Single digit numbers must have 0 in front of them. Ex: barcode07 |
| `Sample ID` | Custom sample name. Convert all spaces in sample names to underscores (`_`).                                                                                                                       |
| `Sample Type` | The sample type for the given sample. Ex: test, positive, negative, etc.                                                                                                                         |

### amd platform samplesheet set up

Illumina data should be set up as follows:

```csv
sample,fastq_1,fastq_2,sample_type
CONTROL_REP1,<FILE_PATH>/fastqs/AEG588A1_S1_L002_R1_001.fastq.gz,<FILE_PATH>/fastqs/AEG588A1_S1_L002_R2_001.fastq.gz,- control
TREATMENT_REP1,<FILE_PATH>/fastqs/AEG588A4_S4_L003_R1_001.fastq.gz,<FILE_PATH>/fastqs/AEG588A4_S4_L003_R2_001.fastq.gz,test
TREATMENT_REP2,<FILE_PATH>/fastqs/AEG588A5_S5_L003_R1_001.fastq.gz,<FILE_PATH>/fastqs/AEG588A5_S5_L003_R2_001.fastq.gz,test
TREATMENT_REP3,<FILE_PATH>/fastqs/AEG588A6_S6_L003_R1_001.fastq.gz,<FILE_PATH>/fastqs/AEG588A6_S6_L003_R2_001.fastq.gz,test
```

| Column    | Description                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Illumina short reads 1. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |
| `fastq_2` | Full path to FastQ file for Illumina short reads 2. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |
| `sample_type` | The sample type for the given sample. Ex: test, - control, + control, etc.                                                                                                         |

ONT data should be set up as follows:

```csv
sample,fastq_1,fastq_2,barcodes,sample_type
s1,<FILE_PATH>/fastq_pass/cat_fastqs/s1.fastq.gz,,barcode27,Test
s2,<FILE_PATH>/fastq_pass/cat_fastqs/s2.fastq.gz,,barcode37,Test
s3,<FILE_PATH>/fastq_pass/cat_fastqs/s3.fastq.gz,,barcode41,Test

```

| Column    | Description                                                                                                                                                                                       |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`).            |
| `fastq_1` | Full path to FastQ file for ONT that have been concatenated by barcode. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                    |
| `fastq_2` | Leave blank for ONT data.                                                                                                                                                                         |
| `barcode` | The barcode used to create the ONT data for this sample. Must match the fold contain the fastq files associated with the sample. Single digit numbers must have 0 in front of them. Ex: barcode07 |
| `sample_type` | The sample type for the given sample. Ex: test, - control, + control, etc.                                                                                                                    |

### File set-up with MIRA samplesheet

After creating the samplesheet, move it into a run folder with fastq files:

Illumina set up should be set up as follows:

1. <RUN_PATH>/fastqs <- all fastq files should be out at this level
2. <RUN_PATH>/samplesheet.csv

Oxford Nanopore set up should be set up as follows:

1. <RUN_PATH>/fastq_pass <- fastq files should be within barcode folders as given by ONT machine
2. <RUN_PATH>/samplesheet.csv

**Note:** The name of the run folder will be used to name outputs files

### File set-up with amd platform samplesheet

After creating the samplesheet, move it into a run folder with fastq files:

Illumina set up should be set up as follows:

1. <RUN_PATH>/fastqs <- all fastq files should be out at this level
2. <RUN_PATH>/samplesheet.csv

Oxford Nanopore set up should be set up as follows:

1. <RUN_PATH>/fastq_pass/cat_fastqs <- all concatenated fastq files should be out at this level
2. <RUN_PATH>/samplesheet.csv

## Running the pipeline

# Input Parameters for MIRA-NF

| Flag       | Description                                                                                                           |
|------------|-----------------------------------------------------------------------------------------------------------------------|
| `profile`  | singularity, docker, local, sge, slurm. You can use docker or singularity. Use local for running on local computer.   |
| `input`    | `<RUN_PATH>/samplesheet.csv` with the format described above. The full file path is required.                         |
| `outdir`   | The file path to where you would like the output directory to write the files. The full file path is required.        |
| `runpath`  | The `<RUN_PATH>` where the samplesheet is located. Your fastq_folder and samplesheet.csv should be in here. The full file path is required. |
| `e`        | Experiment type, options: Flu-ONT, SC2-Spike-Only-ONT, Flu-Illumina, SC2-Whole-Genome-ONT, SC2-Whole-Genome-Illumina, RSV-Illumina, RSV-ONT. |

### *all commands listed below can not be included in run command and the defaults will be used, aside from the p flag that must be used wit hSC2 and RSV pipelines*

| Flag                  | Description                                                                                                                                                                                                                       |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `p`                   | Provide a built-in primer schema if using experiment type SC2-Whole-Genome-Illumina. SARS-CoV-2 options: articv3, articv4, articv4.1, articv5.3.2, qiagen, swift, swift_211206. RSV options: RSV_CDC_8amplicon_230901 **Will be overwritten by custom_primers flag if both flags are provided** |
| `custom_primers`      | Provide a custom primer schema by entering the file path to your own custom primer fasta file. Must be fasta formatted. **primer_kmer_len and primer_restrict_window flags must also be used with this flag**                      |
| `primer_kmer_len`     | When primer_kmer_len is set to K, all K-mers for the primers are stored and matching against K-mers in the queries (reads) is performed.                                                                                          |
| `primer_restrict_window` | The N number of bases provided by this flag will restrict them primer searching to the leftmost and rightmost N bases.                                                                                                           |
| `read_qc`             | (optional) Run FastQC and MultiQC. Default: false.                                                                                                                                                                                |
| `reformat_tables`     | (optional) Flag to reformat report tables into parquet files and csv files (boolean). Default set to false.                                                                                                                        |
| `subsample_reads`     | (optional) The number of reads that used for subsampling. Paired reads for Illumina data and single reads for ONT data. Default is set to skip subsampling process using value 0.                                                  |
| `process_q`           | (required for hpc profile) Provide the name of the processing queue that will submit to the queue.                                                                                                                                |
| `email`               | (optional) Provide an email if you would like to receive an email with the irma summary upon completion.                                                                                                                          |
| `irma_module`         | (optional) Call flu-sensitive, flu-secondary or flu-utr irma module instead of the built-in flu configs. Default is set to not use these modules and they can only be invoked for Flu-Illumina experiment type. Options: sensitive, secondary or utr |
| `custom_irma_config`  | (optional) Provide a custom IRMA config file to be used with IRMA assembly. File path to file needed.                                                                                                                             |
| `custom_qc_settings`  | (optional) Provide custom qc pass/fail settings for constructing the summary files. Default settings can be found in ../bin/irma_config/qc_pass_fail_settings.yaml. File path to file needed.                                     |
| `amd_platform`        | (optional) This flag allows the user to skip the "Nextflow samplesheet creation" step. It will require the user to provide a different samplesheet that is described under "Nextflow samplesheet setup" in the usage.md document. Please read the usage.md fully before implementing this flag. Default false. Options true or false |
| `ecr_registry`        | (optional) Allows a user to pass their ecr registry for AWS to the workflow.                                                                                                                                                      |
| `sourcepath`          | (optional) If sourcepath flag is given, then it will use the sourcepath to point to the reference files, primer fastas and support files in all trimming modules, prepareIRMAjson and staticHTML. This flag is for if one cannot place the entire repo in their working directory. |

To run locally you will need to install Nextflow and singularity-ce or docker on your computer (see links above for details) or you can use an interactive session on an hpc. The command will be run as seen below:

```bash
nextflow run ./main.nf \
   -profile singularity,local \
   --input <RUN_PATH>/samplesheet.csv \
   --outdir <OUTDIR> \
   --runpath <RUN_PATH> \
   --e <EXPERIMENT_TYPE> \
   --p <PRIMER_SCHEMA> \ (optional)
   --custom_primers <CUSTOM_PRIMERS> <FILE_PATH>/custom_primer.fasta (optional) \
   --primer_kmer_len <KMER_LEN> \ (used with custom primers flag)
   --primer_restrict_window <RESTRICT_WIN> \ (used with custom primers flag)
   --subsample_reads <READ_COUNT> \ (optional)
   --reformat_tables true \ (optional)
   --read_qc false \ (optional)
```

To run in a high computing cluster you will need to add hpc to the profile and provide a queue name for the queue that you would like jobs to be submitting to:

```bash
nextflow run ./main.nf \
   -profile singularity,hpc \
      --input <RUN_PATH>/samplesheet.csv \
   --outdir <OUTDIR> \
   --runpath <RUN_PATH> \
   --e <EXPERIMENT_TYPE> \
   --p <PRIMER_SCHEMA> \ (optional)
   --custom_primers <CUSTOM_PRIMERS> <FILE_PATH>/custom_primer.fasta (optional) \
   --primer_kmer_len <KMER_LEN> \ (used with custom primers flag)
   --primer_restrict_window <RESTRICT_WIN> \ (used with custom primers flag)
   --subsample_reads <READ_COUNT> \ (optional)
   --reformat_tables true \ (optional)
   --read_qc false \ (optional)
   --email <EMAIL_ADDRESS> \ (optional)
```

Both of these will launch the pipeline with the `singularity` configuration profile. See below for more information about profiles.

For running MIRA-NF in AWS, example parameter json files for all data types can be found under /samples/examples.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

:::warning
Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).
:::

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run ./main/nf -profile docker -params-file params.yaml
```

with `params.yaml` containing:

```yaml
input: '/RUN_PATH/samplesheet.csv'
outdir: '/FILE_PATH/results/'
runpath: '/RUN_PATH/'
e: 'experiment_type'
p: 'primer_schema' (optional)
custom_primer: '/FILE_PATH/custom_primer.fasta'
primer_kmer_len: 'kmer_len' (used with custom primers flag)
primer_restrict_window: 'restrict_window' (used with custom primers flag)
subsample_reads: 'read_counts' (optional)
reformat_tables: true (optional)
irma_config: 'config_type' (optional)
email: 'email' (optional)
amd_platform: false (optional)
read_qc: false (optional)
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### To See MIRA Utility Workflows

- [find_variants_of_interest](docs/find_variants_of_interest_docs/) - Will run (or rerun) the DAIS-ribosome and finding variants of interest part of the workflow.

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
git clone https://github.com/CDCgov/MIRA-NF.git
cd MIRA-NF
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [mira/nf releases page](https://github.com/mira/nf/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
:::

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so only the profile (singularity or docker) parameter is needed.
  - will make a directory named "testing_config".
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/). Must have docker running for this profile to work.
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `sge`
  - A configuration profile that enables the pipeline to be executed on an HPC with a Sun Grid Engine (SGE) job scheduling system.
- `slurm`
  - A configuration profile that enables the pipeline to be executed on an HPC or cloud platform with Simple Linux Utility for Resource Management (SLURM) job scheduling system.
- `local`
  - A configuration profile that enables the pipeline to run smoothly on a local machine.
- `standard`
  - A configuration profile that has been configured to run within AWS.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customize the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customizing tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organization are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Azure Resource Requests

To be used with the `azurebatch` profile by specifying the `-profile azurebatch`.
We recommend providing a compute `params.vm_type` of `Standard_D16_v3` VMs by default but these options can be changed if required.

Note that the choice of VM size depends on your quota and the overall workload during the analysis.
For a thorough list, please refer the [Azure Sizes for virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
