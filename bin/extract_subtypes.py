#!/usr/bin/env python

import pandas as pd
import numpy as np
from sys import argv, path, exit, executable
from os.path import dirname, basename, isfile
from glob import glob

try:
    irma_path, variant_xlsx, summary_csv, outfi = argv[1], argv[2], argv[3], argv[4]
except IndexError:
    exit(
        f"\n\tUSAGE: python {__file__} <path/to/workdir/> <path/to/irma/results/> <samplesheet> <ont|illumina> <flu|sc2|sc2-spike|rsv> <irma_config_type>\n"
        f"\n\t\t*Inside path/to/irma/results should be the individual samples-irma-dir results\n"
        f"\n\tYou entered:\n\t{executable} {' '.join(argv)}\n\n"
    )

na_subtypes = {
    "N1": "A_NA_N1",
    "N2": "A_NA_N2",
    "Bvic": "B_NA"
}

def irmabam2df(bamFiles):
    sample_list = []
    files = []
    for f in bamFiles:
        sample = basename(dirname(dirname(dirname(f))))
        sample_list.insert(0,sample)
        files.insert(0,f)
    df = pd.DataFrame()
    df['Sample'] = sample_list
    df['Files'] = files
    return df


ha_df = pd.DataFrame()
na_df = pd.DataFrame()

ha_files = glob(irma_path + "/*/IRMA/*/*HA*bam")
na_files = glob(irma_path + "/*/IRMA/*/*NA*bam")

ha_df = irmabam2df(ha_files)
na_df = irmabam2df(na_files)

# Define a mapping for HA subtypes
ha_mapping = {
    "A_HA_H1.bam": "H1",
    "A_HA_H2.bam": "H2",
    "A_HA_H3.bam": "H3",
    "A_HA_H5.bam": "H5",
    "A_HA_H7.bam": "H7",
    "A_HA_H9.bam": "H9",
    "B_HA.bam": "BVIC"
}

# Define a mapping for NA subtypes
na_mapping = {
    "A_NA_N1.bam": "N1",
    "A_NA_N2.bam": "N2",
    "A_NA_N3.bam": "N3",
    "A_NA_N4.bam": "N4",
    "A_NA_N5.bam": "N5",
    "A_NA_N6.bam": "N6",
    "A_NA_N7.bam": "N7",
    "A_NA_N8.bam": "N8",
    "A_NA_N9.bam": "N9",
    "B_NA.bam": "BVIC"
}

# Assign HA_subtype based on the mapping
ha_df['HA_subtype'] = ha_df.Files.apply(
    lambda x: next((subtype for pattern, subtype in ha_mapping.items() if pattern in x), "Missing")
)

# Assign NA_subtype based on the mapping
na_df['NA_subtype'] = na_df.Files.apply(
    lambda x: next((subtype for pattern, subtype in na_mapping.items() if pattern in x), "Missing")
)

combined = pd.DataFrame()
combined = ha_df.merge(na_df, how="outer", on=["Sample"])
combined["Subtype"] = (
            combined[["HA_subtype", "NA_subtype"]]
            .fillna("")
            .agg("".join, axis=1)
            )
combined['Subtype'] = combined['Subtype'].str.replace(r'^BVICBVIC$', 'BVIC', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H1$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H2$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H3$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H5$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H7$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H9$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N1$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N2$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N4$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N5$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N6$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N7$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N8$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N9$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^MissingMissing$', 'Undetermined', regex=True)

check_b = combined[combined['Subtype'].str.contains('BVIC', na=False)]

if check_b.empty == True:
    print ("No B's found")
else:
    if "aavars.xlsx" in variant_xlsx:
        samples = check_b['Sample']
        table = pd.read_excel(variant_xlsx, header=0, engine="openpyxl")
        for i in samples:
            b_samples= table[table['Sample'].str.contains(i, na=False)]
            b_samples_ha = b_samples[b_samples['Protein'].str.contains('HA1', na=False)]
            if (b_samples_ha == 'BRISBANE60').any().any():
                print("BVIC")
            elif (b_samples_ha == 'PHUKET3073').any().any():
                combined.loc[combined['Sample'] == i, 'Subtype'] = 'BYAM'
                print("BYAM")
    else:
        print("AA variant table not found!")

if "summary.txt" in summary_csv:
    summary_table = pd.read_csv(summary_csv, header=0)

merged_df = summary_table.merge(combined[['Sample', 'Subtype']], on='Sample', how='outer').fillna("Undetermined")

pd.DataFrame.to_csv(merged_df, outfi, sep=",", index=False, header=True)
