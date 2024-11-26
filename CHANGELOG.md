# mira-nf/mira: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.2.0 - 2024.11.07

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)

### Enhancements

-

### Parameters

| Old parameter | New parameter                |
| ------------- | ---------------------------- |
| |  |

## v1.2.0 - 2024.11.07

### Credits

- [Amanda Sullivan](https://github.com/mandysulli)
- [Reina Chau](https://github.com/rchau88)
- [Arumugam Rajarethinam](https://github.com/lochanaarumugam)

### Enhancements

- Now maintaining code on cdcgov.
- [PR #10](https://github.com/CDCgov/MIRA-NF/pull/10) - reformat the outputs structure
- [PR #11](https://github.com/CDCgov/MIRA-NF/pull/11) - changes the parquet_files flag to reformat_tables flag. This flag now reformats the report tables into parquet files and csv files.
- [PR #12](https://github.com/CDCgov/MIRA-NF/pull/12) - Restructure so that the readqc subworkflow only runs when the flag `--read_qc` is set to true. Otherwise FastQC and MultiQC will not run.
- [PR #13](https://github.com/CDCgov/MIRA-NF/pull/13) - creating and updating docker containers so that they contain no vulnerabilities.
- [PR #14](https://github.com/CDCgov/MIRA-NF/pull/14) - updating scripts and logs to reflect new changes.
- [PR #16](https://github.com/CDCgov/MIRA-NF/pull/16) - Continuing to update containers to containers with no vulnerabilities.
- [PR #17](https://github.com/CDCgov/MIRA-NF/pull/17) - Updating Java versions in containers.
- [PR #18](https://github.com/CDCgov/MIRA-NF/pull/18) - Merging all changes that allow MIRA-NF to run in both AWS-omics and on HPC's.
- [PR #19](https://github.com/CDCgov/MIRA-NF/pull/19) - Altering workflows to skip the subsampling process if a values greater than 0 is not provide using the subsample_reads flag
- [PR #20](https://github.com/CDCgov/MIRA-NF/pull/20) - Adding the ecr_registry parameter that allows a user to pass their ecr registry for AWS to the workflow.

### Parameters

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
- [PR #22](https://github.com/CDCgov/MIRA-NF/commit/07f5320ecd2462f62c7b0846fe08fc3dafd94598) - add flag that skips the nf-samplesheet creation step. To use this flag you will have to provide a samplesheet that is described as amd platform format in the usage doc
- [PR #23](https://github.com/CDCgov/MIRA-NF/commit/55c9092dfbbfd9ce639633e38fc49bbda28681af) - added in test profile configuration. Added logos.
- [PR #24](https://github.com/CDCgov/MIRA-NF/commit/c2550c30b44de6cd8b5fe3e0b590a9099bb66a10) - Changed name of hpc profile to sge profile. Added slurm profile.
- [PR #26](https://github.com/CDCgov/MIRA-NF/commit/6baa9681d0c578093d4e32b1f39249104637b206) - Added the RSV Illumina and RSV ONT workflows.

### Parameters

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
