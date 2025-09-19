
---
### Notes on CDC Influenza NGS Quality

High quality influenza consensus sequences across laboratories enable early detection of emerging variants or antigenic/functional changes. CDC therefore recommends strict, standard quality thresholds for routine surveillance.

CDC offers **free, open-source software** to assist with quality control / consensus sequence generation for NGS data.

- [IRMA is CDC's flu virus **assembler**](https://github.com/CDCgov/irma) & variant calling software. It is responsible for >100k flu genome assemblies submitted to public databases. Modernization / new features are being delivered via [IRMA-core](https://github.com/CDCgov/irma-core).
- [MIRA is a **GUI application**](https://cdcgov.github.io/MIRA) that wraps IRMA and performs additional data curation / quality control to assure that consensus sequences meet CDC's quality thresholds. MIRA facilitates batch processing of samples and has a user-friendly graphical interface.
- [MIRA-NF is the **Nextflow CLI**](https://github.com/CDCgov/MIRA-NF) version of MIRA suitable for HPC or local runs.
- [CDC's quality **thresholds** & database submission requirements](https://www.aphl.org/programs/infectious_disease/Documents/US_2025-26_Influenza_Season_Surveillance_Guidance.pdf), including strain naming and metadata inclusion
- **Containers** available for [MIRA](https://hub.docker.com/r/cdcgov/mira), [MIRA-NF](https://hub.docker.com/r/cdcgov/mira-nf), [IRMA](https://hub.docker.com/r/cdcgov/irma), and [IRMA-core](https://github.com/CDCgov/irma-core/pkgs/container/irma-core)

---
