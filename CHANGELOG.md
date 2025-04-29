# mira-nf/mira: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.6.0

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)
- [Reina Chau](https://github.com/rchau88)
- [Kristine Lacek](https://github.com/kristinelacek)
- [Sam Wiley](https://github.com/samcwiley)

### Enhancements

### `Added`

- [PR #52](https://github.com/CDCgov/MIRA-NF/pull/52) - Added BLASTN module and container to Flu-Illumina and Flu-ONT modules. BLAST used to determine if strain is a known positive control or LAIV.
- [PR #55](https://github.com/CDCgov/MIRA-NF/pull/55) - Added new references (N4, N5 and N6) got DAIS-ribosome and update container.

### `Fixed`

- [PR #53](https://github.com/CDCgov/MIRA-NF/pull/53) - Fix error thrown when output directory and input directory have the same name. Address (issues #53)
- [PR #56](https://github.com/CDCgov/MIRA-NF/pull/56) - Minor spelling corrections, including a fix for parsing user-provided input for `artic` primers files in `prepilluminareads.nf`

### `Dependencies`

### `Deprecated`

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

| Old parameter | New parameter                |
| ------------- | ---------------------------- |
| | `--sourcepath` |
| | `--irma_custom_config` |
|`--irma_config` | `--irma_module` |

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

| Old parameter | New parameter                |
| ------------- | ---------------------------- |
| `--parquet_files` | `--reformat_tables` |
|                    | `--read_qc` |
|                    | `--ecr_registry` |

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

| Old parameter | New parameter                |
| ------------- | ---------------------------- |
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
