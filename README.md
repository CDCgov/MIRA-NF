[![GitHub Actions CI Status](https://github.com/mira-nf/mira/workflows/nf-core%20CI/badge.svg)](https://github.com/mira-nf/mira/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/mira-nf/mira/workflows/nf-core%20linting/badge.svg)](https://github.com/mira-nf/mira/actions?query=workflow%3A%22nf-core+linting%22)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/mira-nf/mira)

**General disclaimer:** This repository was created for use by CDC programs to collaborate on public health related projects in support of the CDC mission. GitHub is not hosted by the CDC, but is a third party website used by CDC and its partners to share information and collaborate on software. CDC use of GitHub does not imply an endorsement of any one particular service, product, or enterprise.

Use of this service is limited only to non-sensitive and publicly available data. Users must not use, share, or store any kind of sensitive data like health status, provision or payment of healthcare, Personally Identifiable Information (PII) and/or Protected Health Information (PHI), etc. under ANY circumstance.

Administrators for this service reserve the right to moderate all information used, shared, or stored with this service at any time. Any user that cannot abide by this disclaimer and Code of Conduct may be subject to action, up to and including revoking access to services.

The material embodied in this software is provided to you "as-is" and without warranty of any kind, express, implied or otherwise, including without limitation, any warranty of fitness for a particular purpose. In no event shall the Centers for Disease Control and Prevention (CDC) or the United States (U.S.) government be liable to you or anyone else for any direct, special, incidental, indirect or consequential damages of any kind, or any damages whatsoever, including without limitation, loss of profit, loss of use, savings or revenue, or the claims of third parties, whether or not CDC or the U.S. government has been advised of the possibility of such loss, however caused and on any theory of liability, arising out of or in connection with the possession, use or performance of this software.

## Introduction

**mira-nf/mira** is a bioinformatics pipeline that assembles Influenza genomes, SARS-CoV-2 genomes and the SARS-CoV-2 spike-gene when given the raw fastq files and a samplesheet. mira-nf/mira can analyze reasds from both Illumina and OxFord Nanopore sequencing machines.

MIRA performs these steps for genome assembly and curation:

1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))
3. Subsampling to faster analysis ([`bbtools`](https://jgi.doe.gov/data-and-tools/software-tools/bbtools/))
4. Trimming and Quality Filtering ([`bbduk`](https://jgi.doe.gov/data-and-tools/software-tools/bbtools/bb-tools-user-guide/bbduk-guide/))
5. Adapter removal ([`cutadapt`](https://github.com/marcelm/cutadapt/))
6. Genome Assembly ([`IRMA`](https://wonder.cdc.gov/amd/flu/irma/))
7. Annotation of assembly ([`DAIS-ribosome`](https://hub.docker.com/r/cdcgov/dais-ribosome))
8. Collect results from IRMA and DAIS-Ribosome in json files
9. Create html, excel files and amended consensus fasta files
10. Convert into parquet files

MIRA is able to analyze 5 data types:

1. Flu-Illumina - Flu whole genome data created with an illumina machine
2. Flu-ONT - Flu whole genome data created with an OxFord nanopore machine
3. SC2-Whole-Genome-Illumina - SARS-CoV-2 whole genome data created with an illumina machine
4. SC2-Whole-Genome-ONT - SARS-CoV-2 whole genome data created with an OxFord nanopore machine
5. SC2-Spike-Only-ONT - SARS-CoV-2 spike protein data created with an OxFord nanopore machine

![Alt text](docs/images/mira_nf_workflow_image.png)

## Usage

> To run this pipeline you will need to have these programs installed:

1. Nextflow - If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow.
2. singularity-ce or docker - Information on how to install singularity-ce can be found [here](https://docs.sylabs.io/guides/4.1/user-guide/quick_start.html#quick-installation-steps) and information to install docker can be found [here](https://www.docker.com/).
3. git - INformation about git installation can be found [here](<https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>).

Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data. If you would like to test the pipeline using our test data it can be downloaded from this link:

- Tiny test data from ONT Influenza genome and SARS-CoV-2-spike - 40Mb [Download](https://centersfordiseasecontrol.sharefile.com/d-s839d7319e9b04e2baba07b4d328f02c2).
- Full test data set - the data set from above + full genomes of Influenza and SARS-CoV-2 from Illumina MiSeqs 1 Gb [Download](<https://centersfordiseasecontrol.sharefile.com/d-s3c52c0b25c2243078f506d60bd787c62>).

To run this pipeline:

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

Illumina data should be set up as follows:

```csv
Sample ID,Sample Type
sample_1,Test
sample_2,Test
sample_3,Test
sample_4,Test
```

Oxford Nanopore data should be set up as follows:

```csv
Barcode #,Sample ID,Sample Type
barcode07,s1,Test
barcode37,s2,Test
barcode41,s3,Test
```

Each row represents a sample.

Second, move samplesheet into a run folder with fastq files:

Illumina set up should be set up as follows:

1. <RUN_PATH>/fastqs <- all fastqs should be out at this level
2. <RUN_PATH>/samplesheet.csv

Oxford Nanopore set up should be set up as follows:

1. <RUN_PATH>/fastq_pass <- fastqs should be within barcode folders as given by ONT machine
2. <RUN_PATH>/samplesheet.csv

**Note:** The name of the run folder will be used to name outputs files.

Third, pull the mira-nf work flow from github using:

```bash
git clone https://github.com/cdcent/mira-nf.git
cd mira-nf
```

**using dev branch temporary

Now, you can run the pipeline using two methods: locally or within a high computing cluster. In both cases you will need to launch the workflow from the mira-nf folder.

Input parameters for the pipeline include:

- profile - singularity,docker,local,hpc \ You can use docker or singularity. Use local for running on local computer and hpc for running on an hpc.
- input - <RUN_PATH>/samplesheet.csv with the format described above.
- outdir - The file path to where you would like the output directory to write the files.
- runpath - The <RUN_PATH> where the samplesheet is located. Your fastq_folder and samplesheet.csv should be in here.
- e - experiment type, options: Flu-ONT, SC2-Spike-Only-ONT, Flu-Illumina, SC2-Whole-Genome-ONT, SC2-Whole-Genome-Illumina.

*all commands listed below can not be included in run command and the defaults will be used*

- p - provide a built in primer schema if using experement type SC2-Whole-Genome-Illumina. options: articv3, articv4, articv4.1, articv5.3.2, qiagen, swift, swift_211206. **Will be overwritten by custom_primers flag if both flags are provided**
- custom_primers - provide a custom primer schema by entering the file path to your own custom primer fasta file. Must be fasta formated. **Trimming will only work with custom primers that are greater than 15bp**
- parquet_files - (optional) flag to produce parquet files (boolean). Default set to false.
- subsample_reads - (optional) The number of reads that used for subsampling. Paired reads for Illumina data and single reads for ONT data. Default 10,000,000. options: true or false
- process_q - (required for hpc profile)  provide the name of the processing queue that will submit to the queue.
- email - (optional) provide an email if you would like to receive an email with the irma summary upon completion.
- irma_config - (optional) Call flu-sensitive, flu-secondary or flu-utr irma config instead of the built in flu configs. Defaults set to not use these configs. options: sensitive or secondary

To run locally you will need to install Nextflow and singularity-ce on your computer (see links above for details) or you can use an interactive session on an hpc. The command will be run as seen below:

```bash
nextflow run ./main.nf \
   -profile singularity,local \
   --input <RUN_PATH>/samplesheet.csv \
   --outdir <OUTDIR> \
   --runpath <RUN_PATH> \
   --e <EXPERIMENT_TYPE> \
   --p <PRIMER_SHEMA> (optional) \
   --custom_primers <CUSTOM_PRIMERS> <FILE_PATH>/custom_primer.fasta (optional) \
   --subsample_reads <READ_COUNT> \
   --parquet_files true (optional) \
   --irma_config <CONFIG_TYPE> (optional) \
   --email <EMAIL_ADDRESS> (optional)
```

To run in a high computing cluster you will need to add hpc to the profile and provide a queue name for the queue that you would like jobs to be submitting to:

```bash
nextflow run ./main.nf \
   -profile singularity,hpc \
   --input <RUN_PATH>/samplesheet.csv \
   --outdir <RUN_PATH> \
   --runpath <RUN_PATH> \
   --e <EXPERIMENT_TYPE> \
   --p <PRIMER_SHEMA> (optional) \
   --custom_primers <CUSTOM_PRIMERS> <FILE_PATH>/custom_primer.fasta (optional) \
   --process_q <QUEUE_NAME> \
   --parquet_files true (optional) \
   --irma_config <CONFIG_TYPE> (optional) \
   --email <EMAIL_ADDRESS> (optional)
```

For in house testing (all values must be filled in to execute qsub - for primer schema if none, put none):

```bash
qsub MIRA_nextflow.sh \
   -d <FILE_PATH_TO_MIRA-NF_DIR> \
   -f singularity,hpc \
   -i <RUN_PATH>/samplesheet.csv \
   -o <OUTDIR> \
   -r <RUN_PATH> \
   -e <EXPERIMENT_TYPE> \
   -p <PRIMER_SHEMA> \ (optional)
   -g <FILE_PATH>/custom_primer.fasta \ (optional)
   -q <QUEUE_NAME> \
   -a <PARQUET_FILE_CREATION> \ (optional)
   -c <SUBSAMPLED_READ_COUNTS> \ (optional)
   -b <OTHER_IRMA_CONFIG> (optional)
   -m <EMAIL_ADDRESS> \ (optional)

```

> [!WARNING]
> Please provide pipeline parameters via the NF or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration ***except for parameters***;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

## Credits

mira-nf/mira is developed and maintained by Ben Rambo-Martin, Kristine Lacek, Reina Chau, and Amanda Sullivan.

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use mira-nf/mira for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> *Nat Biotechnol.* 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
