
---

### Notes on Influenza NGS Quality
Genomic surveillance depends on standardized, reproducible consensus sequences across laboratories to enable early detection of emerging variants and subtle antigenic or functional changes. Therefore, CDC recommends uniform thresholds that are often stricter and less exploratory than criteria used in individual research studies, which may tolerate greater variability for hypothesis generation.

CDC offers freely-available, open-source software to assist with quality control and consensus sequence generation from influenza virus NGS data.
- IRMA: The Iterative Refinement Meta-Assembler is CDC's influenza virus assembly and variant calling software and is responsible for over 100,000 influenza virus genome assemblies submitted to public databases.
    - https://github.com/CDCgov/irma

- MIRA is a pipeline that runs IRMA and performs additional data curation and quality control to assure that consensus sequences meet CDC's quality thresholds. MIRA facilitates batch processing of samples and can be operated through a user-friendly graphical interface or with the command-line locally or on HPC clusters.
    - https://cdcgov.github.io/MIRA

Specific quality thresholds and database submission requirements including strain naming and metadata inclusion can be found at https://www.aphl.org/programs/infectious_disease/Documents/US_2025-26_Influenza_Season_Surveillance_Guidance.pdf

---