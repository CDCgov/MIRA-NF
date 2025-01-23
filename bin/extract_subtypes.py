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

ha_df['HA_subtype'] = np.where(ha_df.Files.str.contains("A_HA_H1.bam"), "H1",
                   np.where(ha_df.Files.str.contains("A_HA_H3.bam"), "H3",
                   np.where(ha_df.Files.str.contains("A_HA_H5.bam"), "H5", 
                   np.where(ha_df.Files.str.contains("B_HA.bam"), "BVIC", "Missing"))))

na_df['NA_subtype'] = np.where(na_df.Files.str.contains("A_NA_N1.bam"), "N1",
                   np.where(na_df.Files.str.contains("A_NA_N2.bam"), "N2",
                   np.where(na_df.Files.str.contains("B_NA.bam"), "BVIC", "Missing")))

combined = pd.DataFrame()
combined = ha_df.merge(na_df, how="outer", on=["Sample"])
combined["Subtype"] = (
            combined[["HA_subtype", "NA_subtype"]]
            .fillna("")
            .agg("".join, axis=1)
            )
combined['Subtype'] = combined['Subtype'].str.replace(r'^BVICBVIC$', 'BVIC', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H1$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H3$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^H5$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N1$', 'Undetermined', regex=True)
combined['Subtype'] = combined['Subtype'].str.replace(r'^N2$', 'Undetermined', regex=True)

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