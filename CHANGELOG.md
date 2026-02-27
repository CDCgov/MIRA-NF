# cdcgov/mira-nf: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.0.0 - 02.13.2026

- [Amanda Sullivan](https://github.com/mandysulli)
- [Sam Wiley](https://github.com/samcwiley)

### Associated Tags

| Program       | Version |
| ------------- | ------- |
| irma-core     | 0.6.1   |
| IRMA          | 1.3.1   |
| DAIS-ribosome | 1.6.1   |
| mira-oxide    | 1.3.1   |
| nextclade     | 3.18.1  |

### Nextclade Tags Used

| Dataset        | Tag                   |
| -------------- | --------------------- |
| flu_h3n2_ha    | 2024-11-27--02-51-00Z |
| flu_h1n1pdm_ha | 2024-11-27--02-51-00Z |
| flu_vic_ha     | 2024-01-16--20-31-02Z |
| flu_h3n2_na    | 2024-11-05--09-19-52Z |
| flu_h1n1pdm_na | 2024-11-05--09-19-52Z |
| flu_vic_na     | 2024-01-16--20-31-02Z |
| rsv_a          | 2025-08-25--09-00-35Z |
| rsv_b          | 2024-08-01--22-31-31Z |
| sars-cov-2     | 2024-04-25--01-03-07Z |

### Enhancements

### `Added`

- [PR #76](https://github.com/CDCgov/MIRA-NF/pull/76) - added both the find_variants_of_interest module that can be run as a part of analysis and the find_variants_of_interest workflow that run the the workflow described [here](docs/find_variants_of_interest_docs/).
- [PR #82](https://github.com/CDCgov/MIRA-NF/pull/82) - added a `check_version` flag that can be set to false so that MIRA-NF can be run with docker without internet. Default is set to true.
- [PR #84](https://github.com/CDCgov/MIRA-NF/pull/84) - added IRMA-core's standalone `sampler` module for subsampling single and paired-read `.fastq` files, replacing BBTools' `reformat.sh`.
- [PR #88](https://github.com/CDCgov/MIRA-NF/pull/88) - Added filtering to a single subtype for the variants_of_interest and positions_of_intrest outputs if the virus flu (as "INFLUENZA") is passed to the program.
- [PR #94](https://github.com/CDCgov/MIRA-NF/pull/94) - Subtype in the summary report for all viruses now.
- [PR #94](https://github.com/CDCgov/MIRA-NF/pull/94) - Added `custom_runid` flag to allow the user to pass a custom runid used to name outputs files. Otherwise the run folder name will be striped from runpath and used to name outputs.
- [PR #95](https://github.com/CDCgov/MIRA-NF/pull/95) - Added arm64 profiles for improved compatibilaty.
- [PR #96](https://github.com/CDCgov/MIRA-NF/pull/96) - Added Nextclade subworkflow that gets a nextclade database base on subtpye (and segment for flu) and runs nextclade when the `--nextclade` flag is used.
- [PR #97](https://github.com/CDCgov/MIRA-NF/pull/96) - Updated nf-core template to v3.3.2 and fixed formatting and whitespace issues.
- [PR #98](https://github.com/CDCgov/MIRA-NF/pull/98) - replaced alleles.json with minor_variants.json - will break MIRA GUI until updated

### `Fixed`

- [PR #77](https://github.com/CDCgov/MIRA-NF/pull/77) - Update the nextflow schema with nf-core v3.2.0. Pipeline passing lint with nf-core v3.2.0 now.
- [PR #85](https://github.com/CDCgov/MIRA-NF/pull/85) - replaced `findchemistryi.py` and `findchemistryo.py` with `findchemistry.rs` from `mira-oxide`.
- [PR #90](https://github.com/CDCgov/MIRA-NF/pull/90) - Bug squash. Fix "MissingMissing" subtype in mira_summary report.
- [PR #98](https://github.com/CDCgov/MIRA-NF/pull/98) - reading in the allAlleles.txt files for the all_alleles.parq now - may break schemas

### `Dependencies`

- [PR #96](https://github.com/CDCgov/MIRA-NF/pull/96) - new container `nextstrain/nextclade:3.18.1` for running nexclade.
- [PR #98](https://github.com/CDCgov/MIRA-NF/pull/98) - updating mira-oxide container to v1.4.0
- [PR #98](https://github.com/CDCgov/MIRA-NF/pull/98) - removing the use of the `cdcgov/mira-nf:python3.10-alpine` container

### `Deprecated`

- [PR #84](https://github.com/CDCgov/MIRA-NF/pull/54) - Removed BBTools `reformat.sh` for subsampling.
- [PR #92](https://github.com/CDCgov/MIRA-NF/pull/92) - replaced `checkmiraversion.py` with `checkmiraversion.rs` from `mira-oxide`.
- [PR #94](https://github.com/CDCgov/MIRA-NF/pull/94) - replaced `prepareIRMAjson.py`, `irma2pandas.py`, `dais2pandas.py` `parquet_maker.py` and `extract_subtypes.py` with `prepare-mira-report` from `mira-oxide`.
- [PR #94](https://github.com/CDCgov/MIRA-NF/pull/94) - replaced `prepareirmajson.nf`, `statichtml.nf`, `parquetmaker.nf` and `addflusubtype.nf` with `preparemirareports.nf` and `preparemirareportswithparq.nf`.
- [PR #94](https://github.com/CDCgov/MIRA-NF/pull/94) - replaced the `reformat_tables` flag with the `parquet_files` flag. CSV files now automatically generate and the `parquet_files` flag will iniate the generation of parquet files.
- [PR #94](https://github.com/CDCgov/MIRA-NF/pull/94) - No longer creating XSLX files in the `mira-reports` folder. CSV files are always geenrated to replace them.
- [PR #98](https://github.com/CDCgov/MIRA-NF/pull/98) - No longer making alleles.json or all_alleles.csv
- [PR #98](https://github.com/CDCgov/MIRA-NF/pull/98) - minor_variants.csv and minor_variants.parq no longer filtered to frequency of 0.05
- [PR #98](https://github.com/CDCgov/MIRA-NF/pull/98) - the minor_indel_count column has been removed from summary.csv, summary.json and summary.parq - may break schemas

### Parameter Changes

| Old parameter       | New parameter            |
| ------------------- | ------------------------ |
|                     | `--variants_of_interest` |
|                     | `--postions_of_interest` |
|                     | `--reference_seq_table`  |
|                     | `--dais_module`          |
|                     | `--check_version`        |
| `--reformat_tables` | `--parquet_files`        |
|                     | `--nextclade`            |

## v1.6.1 - 06.04.2025

- [Amanda Sullivan](https://github.com/mandysulli)
- [Sam Wiley](https://github.com/samcwiley)
- [Ben Rambo-Martin](https://github.com/nbx0)

### Enhancements

### `Added`

-[PR #70](https://github.com/CDCgov/MIRA-NF/pull/70) - adding docker version tracking

### `Fixed`

-[PR #72](https://github.com/CDCgov/MIRA-NF/pull/72) - fix a polyg trimming bug in irma-core trimmer

### `Dependencies`

-[PR #73](https://github.com/CDCgov/MIRA-NF/pull/73) - updating the IRMA container to v1.3.0

### `Deprecated`

## v1.6.0 - 05.21.2025

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)
- [Sam Wiley](https://github.com/samcwiley)
- [Kristine Lacek](https://github.com/kristinelacek)
- [Reina Chau](https://github.com/rchau88)
- [Ben Rambo-Martin](https://github.com/nbx0)

### Enhancements

### `Added`

- [PR #55](https://github.com/CDCgov/MIRA-NF/pull/55) - Added new references (N4, N5 and N6) got DAIS-ribosome and update container.
- [PR #66](https://github.com/CDCgov/MIRA-NF/pull/64) - Added the ability to do custom primer trimming with the Flu-Illumina module

### `Fixed`

- [PR #53](https://github.com/CDCgov/MIRA-NF/pull/53) - Fix error thrown when output directory and input directory have the same name. Address (issues #53)
- [PR #56](https://github.com/CDCgov/MIRA-NF/pull/56) - Minor spelling corrections, including a fix for parsing user-provided input for `artic` primers files in `prepilluminareads.nf`

### `Dependencies`

- [PR #54](https://github.com/CDCgov/MIRA-NF/pull/54), [PR #59](https://github.com/CDCgov/MIRA-NF/pull/59) and [PR #66](https://github.com/CDCgov/MIRA-NF/pull/64)- Added IRMA-core's standalone `trimmer` module for handling barcode, primer, and hard trimming for prepping ONT and Illumina reads, replacing BBDuk and cutadapt

### `Deprecated`

- [PR #54](https://github.com/CDCgov/MIRA-NF/pull/54) - Removed `cutadapt` for hard trimming reads.
- [PR #59](https://github.com/CDCgov/MIRA-NF/pull/59) - Removed BBDuk for handling barcode and primer trimming of reads.
- [PR #66](https://github.com/CDCgov/MIRA-NF/pull/64) - Only performing the staging of Illumina fastq files for the standard (AWS) profile. It was removed for all other profiles.

## v1.5.0 - 2025.04.02

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)
- [Reina Chau](https://github.com/rchau88)

### Enhancements

### `Added`

### `Fixed`

- [PR #50](https://github.com/CDCgov/MIRA-NF/pull/50) - Updated containers to work with docker, local profiles better.

### `Dependencies`

### `Deprecated`

## v1.4.3 - 2025.03.31

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)

### Enhancements

### `Added`

### `Fixed`

- [PR #49](https://github.com/CDCgov/MIRA-NF/pull/49) - fixed binding to dais ribosome containers with docker profile.
- [PR #62](https://github.com/CDCgov/MIRA-NF/pull/62) - fixed empty dataframe handling in prepareIRMAjson.py.

### `Dependencies`

### `Deprecated`

## v1.4.2 - 2025.03.31

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)
- [Kristine Lacek](https://github.com/kristinelacek)

### Enhancements

### `Added`

### `Fixed`

- [PR #48](https://github.com/CDCgov/MIRA-NF/pull/48) - fixed the docker profile in the nextflow.config.

### `Dependencies`

- [PR #45](https://github.com/CDCgov/MIRA-NF/pull/45) - Updated DAIS ribosome references to include translated A/Astrakhan N8 reference for compatibility with DAIS ribosome 1.1.5.
- [PR #62](https://github.com/CDCgov/MIRA-NF/pull/45) - Updated DAIS ribosome references to be CVVs for more up to date comparisons.

### `Deprecated`

## v1.4.1

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)

### Enhancements

### `Added`

- [PR #44](https://github.com/CDCgov/MIRA-NF/pull/44) - adding configs for other profiles. restore the base config to it's original settings to be used as a template for other config files.

### `Fixed`

- [PR #43](https://github.com/CDCgov/MIRA-NF/pull/43) - Fixing how the base base is extracted from the run path for naming parquet and cav files. Will now work with "." in the run name.

### `Dependencies`

### `Deprecated`

## v1.4.0 - 2025.01.23

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)

### Enhancements

### `Added`

- [PR #41](https://github.com/CDCgov/MIRA-NF/pull/41) - Adding in the subtype assigned by IRMA in the the summary csv for the flu modules. Only works for flu. Only adds them to the csv outputs.

### `Fixed`

### `Dependencies`

### `Deprecated`

## v1.3.1 - 2024.01.08

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)

### Enhancements

### `Added`

### `Fixed`

- [PR #39](https://github.com/CDCgov/MIRA-NF/pull/39) - Hot fix csv file format

### `Dependencies`

### `Deprecated`

### Parameter Changes

## v1.3.0 - 2024.12.09

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)
- [Reina Chau](https://github.com/rchau88)

### Enhancements

- [PR #24](https://github.com/CDCgov/MIRA-NF/pull/24) - Cleaning up scripts and updating documents.
- [PR #27](https://github.com/CDCgov/MIRA-NF/pull/27) - Updating scripts so that irma_config files are compatible with AWS batch.
- [PR #34](https://github.com/CDCgov/MIRA-NF/pull/33) - Adding instrument type to instruments field when creating parquet and csv files.

### `Added`

- [PR #25](https://github.com/CDCgov/MIRA-NF/pull/25) - If sourcepath flag is given, then it will use the sourcepath to point to the reference files, primer fastas and support files in all trimming modules, prepareIRMAjson and staticHTML. This flag is for if one can not place the entire repo in their working directory.
- [PR #29](https://github.com/CDCgov/MIRA-NF/pull/29) - Adding a custom_irma_config flag that allows user to pass a custom irma config to be passed to the pipeline for IRMA assembly.
- [PR #30](https://github.com/CDCgov/MIRA-NF/pull/30) - Adding a qc_settings flag that allows user to pass a custom qc pass/fail yaml to be passed to the pipeline to specify desired qc standards. Added Error handling.

### `Fixed`

- [PR #36](https://github.com/CDCgov/MIRA-NF/pull/36) - Hot fix of paths broken by updated code
- [PR #39](https://github.com/CDCgov/MIRA-NF/pull/39) - Hot fix csv file format

### `Dependencies`

- [PR #33](https://github.com/CDCgov/MIRA-NF/pull/33) - Scipts and container cdcgov/mira-nf:python3.10-alpine are updated to contain new changes.

### `Deprecated`

- [PR #31](https://github.com/CDCgov/MIRA-NF/pull/31) - renamed --irma_config flag to --irma_module and updated documentation. Added checkmiraversion.nf and checkmiraversion.py to check if users local version of MIRA-NF is up to date. Prints in stdout and email.

### Parameter Changes

| Old parameter   | New parameter          |
| --------------- | ---------------------- |
|                 | `--sourcepath`         |
|                 | `--irma_custom_config` |
| `--irma_config` | `--irma_module`        |

## v1.2.0 - 2024.11.07

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)
- [Reina Chau](https://github.com/rchau88)
- [Arumugam Rajarethinam](https://github.com/lochanaarumugam)

### Enhancements

- Now maintaining code on cdcgov.
- [PR #10](https://github.com/CDCgov/MIRA-NF/pull/10) - reformat the outputs structure
- [PR #14](https://github.com/CDCgov/MIRA-NF/pull/14) - updating scripts and logs to reflect new changes.
- [PR #17](https://github.com/CDCgov/MIRA-NF/pull/17) - Updating Java versions in containers.
- [PR #18](https://github.com/CDCgov/MIRA-NF/pull/18) - Merging all changes that allow MIRA-NF to run in both AWS-omics and on HPC's.
- [PR #19](https://github.com/CDCgov/MIRA-NF/pull/19) - Altering workflows to skip the subsampling process if a values greater than 0 is not provide using the subsample_reads flag

### `Added`

- [PR #12](https://github.com/CDCgov/MIRA-NF/pull/12) - Restructure so that the readqc subworkflow only runs when the flag `--read_qc` is set to true. Otherwise FastQC and MultiQC will not run.
- [PR #20](https://github.com/CDCgov/MIRA-NF/pull/20) - Adding the ecr_registry parameter that allows a user to pass their ecr registry for AWS to the workflow.

### `Fixed`

### `Dependencies`

- [PR #13](https://github.com/CDCgov/MIRA-NF/pull/13) - creating and updating docker containers so that they contain no vulnerabilities.
- [PR #16](https://github.com/CDCgov/MIRA-NF/pull/16) - Continuing to update containers to containers with no vulnerabilities.

### `Deprecated`

- [PR #11](https://github.com/CDCgov/MIRA-NF/pull/11) - changes the parquet_files flag to reformat_tables flag. This flag now reformats the report tables into parquet files and csv files.

### Parameter Changes

| Old parameter     | New parameter       |
| ----------------- | ------------------- |
| `--parquet_files` | `--reformat_tables` |
|                   | `--read_qc`         |
|                   | `--ecr_registry`    |

## v1.1.0 - 2024-09-19

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)

### Enhancements

- [PR #21](https://github.com/CDCgov/MIRA-NF/commit/f9ea0bfb933adf5617920a8a046998e4f5ba304d) - add amended_consensus.fasta to email
- [PR #23](https://github.com/CDCgov/MIRA-NF/commit/55c9092dfbbfd9ce639633e38fc49bbda28681af) - added in test profile configuration. Added logos.

### `Added`

- [PR #22](https://github.com/CDCgov/MIRA-NF/commit/07f5320ecd2462f62c7b0846fe08fc3dafd94598) - add flag that skips the nf-samplesheet creation step. To use this flag you will have to provide a samplesheet that is described as amd platform format in the usage doc
- [PR #24](https://github.com/CDCgov/MIRA-NF/commit/c2550c30b44de6cd8b5fe3e0b590a9099bb66a10) - Changed name of hpc profile to sge profile. Added slurm profile.
- [PR #26](https://github.com/CDCgov/MIRA-NF/commit/6baa9681d0c578093d4e32b1f39249104637b206) - Added the RSV Illumina and RSV ONT workflows.

### `Fixed`

### `Dependencies`

### `Deprecated`

### Parameter Changes

| Old parameter | New parameter    |
| ------------- | ---------------- |
|               | `--amd_platform` |

## v1.0.0 - 2024-08-20

### Credits

- [Ben Rambo-Martin](https://github.com/nbx0)
- [Amanda Sullivan](https://github.com/mandysulli)
- [Kristine Lacek](https://github.com/kristinelacek)
- [Reina Chau](https://github.com/rchau88)

Initial release of mira/nf, created with the [nf-core](https://nf-co.re/) template.

### `Added`

### `Fixed`

### `Dependencies`

### `Deprecated`
