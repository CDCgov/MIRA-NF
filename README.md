[![GitHub Actions CI Status](https://github.com/mira/cli/workflows/nf-core%20CI/badge.svg)](https://github.com/mira/cli/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/mira/cli/workflows/nf-core%20linting/badge.svg)](https://github.com/mira/cli/actions?query=workflow%3A%22nf-core+linting%22)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/mira/cli)

## Introduction

**mira/cli** is a bioinformatics pipeline that ...

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))
3. Trimming and Quality Filtering (['bbduk'])
4. Genome Assembly (['IRMA'](https://wonder.cdc.gov/amd/flu/irma/))

## Usage

:::note
> [!NOTE]
> To run this pipeline you will need to have these programs installed:

1. Nextflow - If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow.
2. singularity - Information on how to install singularity can be found [here](https://docs.sylabs.io/guides/3.0/user-guide/installation.html).
3. git - INformation about git installation can be found [here] (<https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>).

Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data. If you would like to test the pipeline using our test data it can be downloaded from this link:
**ADD**
:::

To run this pipeline:

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

Illumina data should be set up as follows:

```csv
Sample ID,Sample Type,Unnamed: 2
sample_1,Test, nan
sample_2,Test,nan
sample_3,Test,nan
sample_4,Test,nan
```

Oxford Nanopore data should be set up as follows:

```csv
Barcode #,Sample ID,Sample Type
barcode27,s1,Test
barcode37,s2,Test
barcode41,s3,Test
```

Each row represents a sample.

Second, move samplesheet into a run folder with fastq files:

Illumina should be set up as follows:

1. <RUN_PATH>/fastqs <- all fastqs should be out at this level
2. <RUN_PATH>/samplesheet.csv

Oxford Nanopore should be set up as follows:

1. <RUN_PATH>/fastq_pass <- fastqs should be within barcode folders as given by ONT machine
2. <RUN_PATH>/samplesheet.csv

Third, pull the mira-cli work flow from github using:

```bash
git clone https://github.com/cdcent/mira-cli.git
cd mira-cli
git checkout dev
```

**using dev branch temporary

Now, you can run the pipeline using two methods: locally or within a high computing cluster. In both cases you will need to launch the workflow from the mira-cli folder.

To run locally you will need to install Nextflow on your computer (see link above for details) or you can use an interactive session on an hpc. The command will be run as seen below:

```bash
module load nextflow/23.10.0 <later versions may be used>
nextflow run ./main.nf \
   -profile singularity,local \ these profiles must be used in this case
   --input samplesheet.csv \ <RUN_PATH>/samplesheet.csv described above
   --outdir <OUTDIR> \ The <RUN_PATH> described above. Your fastq_folder and samplesheet.csv should be in here
   --e <EXPERIMENT_TYPE> \ options: Flu-ONT, SC2-Spike-Only-ONT, Flu-Illumina, SC2-Whole-Genome-ONT, SC2-Whole-Genome-Illumina
   --p <PRIMER_SHEMA> (optional) \ options: articv3, articv4, articv4.1, articv5.3.2, qiagen, swift, swift_211206
   --process_q <QUEUE> (optional) \ provide queue name if hpc profile has been selected
   --email <EMAIL_ADDRESS> (optional) \ provide an email if you would like to receive an email with the irma summary upon completion
```

To run in a high computing cluster you will need to add hpc to the profile and provide a queue name for the queue that you would like jobs to be submitting to:

```bash
qsub MIRA_nextflow.sh \
   -f singularity,hpc \ these profiles must be used in this case
   -i samplesheet.csv \ <RUN_PATH>/samplesheet.csv described above
   -o <OUTDIR> \ The <RUN_PATH> described above. Your fastq_folder and samplesheet.csv should be in here
   -e <EXPERIMENT_TYPE> \ options: Flu-ONT, SC2-Spike-Only-ONT, Flu_Illumina, SC2-Whole-Genome-ONT, SC2-Whole-Genome-Illumina
   -p <PRIMER_SHEMA> (optional) \ options: articv3, articv4, articv4.1, articv5.3.2, qiagen, swift, swift_211206
   -q <QUEUE> (optional) \ provide queue name if hpc profile has been selected
   -m <EMAIL_ADDRESS> (optional) \ provide an email if you would like to receive an email with the irma summary upon completion
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

## Credits

mira/cli was originally written by Ben Rambo-Martin, Kristine Lacek, Reina Chau, Amanda Sullivan.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use mira/cli for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
