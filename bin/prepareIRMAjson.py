#!/usr/bin/env python

import pandas as pd
import numpy as np
import json
from sys import argv, path, exit, executable
import os.path as op
from os import makedirs
import plotly.graph_objects as go
import plotly.express as px
import plotly.io as pio
import yaml
import time
from glob import glob

path.append(op.dirname(op.realpath(__file__)))
import irma2pandas  # type: ignore
import dais2pandas  # type: ignore

try:
    work_path, irma_path, samplesheet, platform, virus = argv[1], argv[2], argv[3], argv[4], argv[5]
except IndexError:
    exit(
        f"\n\tUSAGE: python {__file__} <path/to/irma/results/> <samplesheet> <ont|illumina> <flu|sc2|sc2-spike|rsv>\n"
        f"\n\t\t*Inside path/to/irma/results should be the individual samples-irma-dir results\n"
        f"\n\tYou entered:\n\t{executable} {' '.join(argv)}\n\n"
    )

# Load qc config:
with open(
    work_path
    + "/bin/irma_config/qc_pass_fail_settings.yaml"
) as y:
    qc_values = yaml.safe_load(y)

qc_plat_vir = f"{platform}-{virus}"

proteins = {
    "sc2": "ORF10 S orf1ab ORF6 ORF8 ORF7a ORF7b M N ORF3a E ORF9b",
    "flu": "PB1-F2 HA M1 NP HA1 BM2 NB PB2 NEP PB1 HA-signal PA-X NS1 M2 NA PA",
    "rsv": "NS1 NS2 N P M SH G F MS-1 M2-2 L"
}
ref_proteins = {
    "ORF10": "SARS-CoV-2",
    "S": "SARS-CoV-2",
    "orf1ab": "SARS-CoV-2",
    "ORF6": "SARS-CoV-2",
    "ORF8": "SARS-CoV-2",
    "ORF7a": "SARS-CoV-2",
    "ORF7b": "SARS-CoV-2",
    "N": "SARS-CoV-2 RSV_AD RSV_BD RSV_A RSV_B",
    "ORF3a": "SARS-CoV-2",
    "E": "SARS-CoV-2",
    "ORF9b": "SARS-CoV-2",
    "SARS-CoV-2": "SARS-CoV-2",
    "PB1-F2": "A_PB1 B_PB1",
    "HA": "A_HA_H10 A_HA_H11 A_HA_H12 A_HA_H13 A_HA_H14 A_HA_H15 A_HA_H16 A_HA_H1 \
        A_HA_H2 A_HA_H3 A_HA_H4 A_HA_H5 A_HA_H6 A_HA_H7 A_HA_H8 A_HA_H9 B_HA",
    "M1": "A_MP B_MP",
    "NP": "A_NP B_NP",
    "HA1": "A_HA_H10 A_HA_H11 A_HA_H12 A_HA_H13 A_HA_H14 A_HA_H15 A_HA_H16 A_HA_H1 \
        A_HA_H2 A_HA_H3 A_HA_H4 A_HA_H5 A_HA_H6 A_HA_H7 A_HA_H8 A_HA_H9 B_HA",
    "BM2": "B_MP",
    "NB": "B_MP",
    "PB2": "A_PB2 B_PB2",
    "NEP": "A_NS B_NS",
    "PB1": "A_PB1 B_PB1",
    "HA-signal": "A_HA_H10 A_HA_H11 A_HA_H12 A_HA_H13 A_HA_H14 A_HA_H15 A_HA_H16 A_HA_H1 \
        A_HA_H2 A_HA_H3 A_HA_H4 A_HA_H5 A_HA_H6 A_HA_H7 A_HA_H8 A_HA_H9 B_HA",
    "PA-X": "A_PA B_PA",
    "NS1": "A_NS B_NS RSV_AD RSV_BD RSV_A RSV_B",
    "NS": "A_NS B_NS",
    "M2": "A_MP B_MP",
    "M": "A_MP B_MP SARS-CoV-2 RSV_AD RSV_BD",
    "NA": "A_NA_N1 A_NA_N2 A_NA_N3 A_NA_N4 A_NA_N5 A_NA_N6 A_NA_N7 A_NA_N8 A_NA_N9 B_NA",
    "PA": "A_PA B_PA",
    "NS2": "RSV_AD RSV_BD RSV_A RSV_B",
    "P": "RSV_AD RSV_BD RSV_A RSV_B",
    "SH": "RSV_AD RSV_BD RSV_A RSV_B",
    "G": "RSV_AD RSV_BD RSV_A RSV_B",
    "F": "RSV_AD RSV_BD RSV_A RSV_B",
    "M2-1": "RSV_AD RSV_BD RSV_A RSV_B",
    "M2-2": "RSV_AD RSV_BD RSV_A RSV_B",
    "L": "RSV_AD RSV_BD RSV_A RSV_B",
}


###############################################################
## Dataframes
###############################################################


def negative_qc_statement(irma_reads_df, negative_list=""):
    if negative_list == "":
        sample_list = list(irma_reads_df["Sample"].unique())
        negative_list = [i for i in sample_list if "PCR" in i]
    irma_reads_df = irma_reads_df.pivot(
        index="Sample", columns="Record", values="Reads"
    ).fillna(0)
    if "3-altmatch" in irma_reads_df.columns:
        irma_reads_df["Percent Mapping"] = (
            irma_reads_df["3-match"] + irma_reads_df["3-altmatch"]
        ) / irma_reads_df["1-initial"]
    else:
        irma_reads_df["Percent Mapping"] = (
            irma_reads_df["3-match"] / irma_reads_df["1-initial"]
        )
    irma_reads_df = irma_reads_df.fillna(0)
    statement_dic = {"passes QC": {}, "FAILS QC": {}}
    for s in negative_list:
        try:
            reads_mapping = irma_reads_df.loc[s, "Percent Mapping"] * 100
        except KeyError:
            reads_mapping = 0
        if reads_mapping >= 0.01:
            statement_dic["FAILS QC"][s] = f"{reads_mapping:.2f}"
        else:
            statement_dic["passes QC"][s] = f"{reads_mapping:.2f}"
    return statement_dic


def which_ref(sample, protein, ref_protein_dic, irma_summary_df):
    try:
        return list(
            set(
                irma_summary_df[irma_summary_df["Sample"] == sample]["Reference"]
            ).intersection(set(ref_protein_dic[protein].split()))
        )[0]
    except IndexError:
        print(
            f"no match found for either sample=={sample} in irma_summary_df\n or protein=={protein} in ref_proteins"
        )
    except ValueError:
        return numpy.nan


def pass_qc(reason, sequence):
    reason, sequence = str(reason), str(sequence)
    if reason == "nan" and sequence != "nan":
        return "Pass"
    elif reason == "nan" and sequence == "nan":
        return "No matching reads"
    else:
        return reason


def anyref(ref):
    if ref == "":
        return "Any"
    else:
        return ref


def failedall(combined_df):
    try:
        for i in combined_df.index:
            if str(combined_df.loc[i][""]) != "nan":
                combined_df.loc[i] = "No assembly"
    except:
        pass
    return combined_df


def pass_fail_qc_df(irma_summary_df, dais_vars_df, nt_seqs_df):
    if not qc_values[qc_plat_vir]["allow_stop_codons"]:
        pre_stop_df = dais_vars_df[dais_vars_df["AA Variants"].str.contains(r"[0-9]\*")][
            ["Sample", "Protein"]
        ]
    else:
        pre_stop_df = pd.DataFrame(columns=["Sample", "Protein"])
    pre_stop_df["Reason_a"] = f"Premature stop codon {set(pre_stop_df['Protein'])}"
    if virus == "flu":
        pre_stop_df["Sample"] = pre_stop_df["Sample"].str[:-2]
    try:
        pre_stop_df["Reference"] = pre_stop_df.apply(
            lambda x: which_ref(
                x["Sample"], x["Protein"], ref_proteins, irma_summary_df
            ),
            axis=1,
        )
    except ValueError:
        pre_stop_df = pd.DataFrame(
            columns=["Sample", "Protein", "Reference", "Reason_a"]
        )
    ref_covered_df = irma_summary_df[
        (
            irma_summary_df["% Reference Covered"]
            < qc_values[qc_plat_vir]["perc_ref_covered"]
        )
    ][["Sample", "Reference"]]
    ref_covered_df[
        "Reason_b"
    ] = f"Less than {qc_values[qc_plat_vir]['perc_ref_covered']}% of reference covered"
    med_cov_df = irma_summary_df[
        (irma_summary_df["Median Coverage"] < qc_values[qc_plat_vir]["med_cov"])
    ][["Sample", "Reference"]]
    med_cov_df["Reason_c"] = f"Median coverage < {qc_values[qc_plat_vir]['med_cov']}"
    minor_vars_df = irma_summary_df[
        (
            irma_summary_df["Count of Minor SNVs >= 0.05"]
            > qc_values[qc_plat_vir]["minor_vars"]
        )
    ][["Sample", "Reference"]]
    minor_vars_df[
        "Reason_d"
    ] = f"Count of minor variants at or over 5% > {qc_values[qc_plat_vir]['minor_vars']}"
    if "sc2" in virus and "spike" not in virus:
        spike_ref_covered_df = irma_summary_df[
            (
                irma_summary_df["% Spike Covered"]
                < qc_values[qc_plat_vir]["perc_ref_spike_covered"]
            )
        ][["Sample", "Reference"]]
        spike_ref_covered_df["Reason_e"] = f"Less than {qc_values[qc_plat_vir]['perc_ref_spike_covered']}% of S gene reference covered"
        spike_med_cov_df = irma_summary_df[
        (irma_summary_df["Spike Median Coverage"] < qc_values[qc_plat_vir]["med_spike_cov"])][["Sample", "Reference"]]
        spike_med_cov_df["Reason_f"] = f"Median coverage of S gene < {qc_values[qc_plat_vir]['med_spike_cov']}"
        if ref_covered_df.empty == False or med_cov_df.empty == False or minor_vars_df.empty == False or pre_stop_df.empty == False or spike_ref_covered_df.empty == False or spike_med_cov_df.empty == False:
            combined = ref_covered_df.merge(med_cov_df, how="outer", on=["Sample", "Reference"])
            combined = combined.merge(minor_vars_df, how="outer", on=["Sample", "Reference"])
            combined = combined.merge(pre_stop_df, how="outer", on=["Sample", "Reference"])
            combined = combined.merge(spike_ref_covered_df, how="outer", on=["Sample", "Reference"])
            combined = combined.merge(spike_med_cov_df, how="outer", on=["Sample", "Reference"])
            combined["Reasons"] = (
            combined[["Reason_a", "Reason_b", "Reason_c", "Reason_d", "Reason_e", "Reason_f"]]
            .fillna("")
            .agg("; ".join, axis=1)
            )
        else:
            combined = pd.DataFrame(columns=['Sample', 'Reference', 'Protein', 'Reasons'])
    else:
        if ref_covered_df.empty == False or med_cov_df.empty == False or minor_vars_df.empty == False or pre_stop_df.empty == False:
            combined = ref_covered_df.merge(med_cov_df, how="outer", on=["Sample", "Reference"])
            combined = combined.merge(minor_vars_df, how="outer", on=["Sample", "Reference"])
            combined = combined.merge(pre_stop_df, how="outer", on=["Sample", "Reference"])   
            combined["Reasons"] = (
            combined[["Reason_a", "Reason_b", "Reason_c", "Reason_d"]]
            .fillna("")
            .agg("; ".join, axis=1)
            )
        else:
            combined = pd.DataFrame(columns=['Sample', 'Reference', 'Protein', 'Reasons'])
    
    # Add in found sequences
    combined = combined.merge(nt_seqs_df, how="outer", on=["Sample", "Reference"])
    combined["Reasons"] = combined.apply(
        lambda x: pass_qc(x["Reasons"], x["Sequence"]), axis=1
    )
    combined = combined[["Sample", "Reference", "Reasons"]]
    try:
        combined["Reasons"] = (
            combined["Reasons"]
            .replace(r"^ \+;|(?<![a-zA_Z0-9]) ;|; \+$", "", regex=True)
            .str.strip()
            .replace("^; *| *;$", "", regex=True)
        )
    except AttributeError:
        combined["Reasons"] = combined["Reasons"].fillna(
            "Too few reads matching reference"
        )
    # combined = combined.merge(
    #    irma_summary_df["Sample"], how="outer", on="Sample"
    # ).drop_duplicates()
    # combined['Reference'] = combined['Reference'].apply(lambda x: anyref(x))
    combined = (
        combined.drop_duplicates().pivot(
            index="Sample", columns="Reference", values="Reasons"
        )
        # .drop(numpy.nan, axis=1)
    )
    combined = combined.apply(lambda x: failedall(x))
    try:
        combined = combined.drop(columns="")
    except KeyError:
        pass
    pd.DataFrame.to_csv(combined, f"combined.csv", sep="\t", index=False, header=True)
    return combined


def perc_len(maplen, ref, ref_lens):
    if ref == "spike":
        return maplen / 3821 * 100
    else:
        return maplen / ref_lens[ref] * 100


def version_module():
    module = qc_plat_vir
    descript_dict = {}
    with open(f"{work_path}/DESCRIPTION", "r") as infi:
        for line in infi:
            try:
                descript_dict[line.split(":")[0]] = line.split(":")[1]
            except:
                continue
    modulestring = f"MIRA-NF-v{descript_dict['Version'].strip()} {module}"
    return modulestring


def irma_summary(
    irma_path, samplesheet, reads_df, indels_df, alleles_df, coverage_df, ref_lens
):
    ss_df = pd.read_csv(samplesheet)
    ss_df["sample"] = ss_df["sample"].astype(str)
    allsamples_df = ss_df[["sample"]].rename(columns={"sample": "Sample"})
    neg_controls = list(ss_df[ss_df["sample_type"] == "- Control"]["sample"])
    qc_statement = negative_qc_statement(reads_df, neg_controls)
    with open(f"./qc_statement.json", "w") as out:
        json.dump(qc_statement, out)
    reads_df = (
        reads_df[reads_df["Record"].str.contains("^1|^2-p|^4")]
        .pivot(index="Sample", columns="Record", values="Reads")
        .reset_index()
        .melt(id_vars=["Sample", "1-initial", "2-passQC"])
        .rename(
            columns={
                "1-initial": "Total Reads",
                "2-passQC": "Pass QC",
                "Record": "Reference",
                "value": "Reads Mapped",
            }
        )
    )
    reads_df = reads_df[~reads_df["Reads Mapped"].isnull()]
    reads_df["Reference"] = reads_df["Reference"].map(lambda x: x[2:])
    # reads_df[["Total Reads", "Pass QC", "Reads Mapped"]] = (
    #    reads_df[["Total Reads", "Pass QC", "Reads Mapped"]]
    #    .applymap(lambda x: f"{x:,d}")
    #    .astype("int")
    # )
    reads_df = reads_df[
        ["Sample", "Total Reads", "Pass QC", "Reads Mapped", "Reference"]
    ]
    indels_df = (
        indels_df[indels_df["Frequency"] >= 0.05]
        .groupby(["Sample", "Reference"])
        .agg({"Sample": "count"})
        .rename(columns={"Sample": "Count of Minor Indels >= 0.05"})
        .reset_index()
    )
    alleles_df = (
        alleles_df[alleles_df["Minority Frequency"] >= 0.05]
        .groupby(["Sample", "Reference"])
        .agg({"Sample": "count"})
        .rename(columns={"Sample": "Count of Minor SNVs >= 0.05"})
        .reset_index()
    )
    cov_ref_lens = (
        coverage_df[~coverage_df["Consensus"].isin(["-", "N", "a", "c", "t", "g"])]
        .groupby(["Sample", "Reference_Name"])
        .agg({"Sample": "count"})
        .rename(columns={"Sample": "maplen"})
        .reset_index()
    )
    cov_ref_lens["% Reference Covered"] = cov_ref_lens.apply(
        lambda x: perc_len(x["maplen"], x["Reference_Name"], ref_lens), axis=1
    )
    cov_ref_lens["% Reference Covered"] = (
        cov_ref_lens["% Reference Covered"].map(lambda x: f"{x:.2f}").astype(float)
    )
    cov_ref_lens = cov_ref_lens[
        ["Sample", "Reference_Name", "% Reference Covered"]
    ].rename(columns={"Reference_Name": "Reference"})
    if virus.lower() == "sc2-spike":
        coverage_df = coverage_df[coverage_df["HMM_Position"].between(21563, 25384)]
    if "sc2" in virus and "spike" not in virus:
        spike_coverage_df = coverage_df[coverage_df["HMM_Position"].between(21563, 25384)]
        spike_cov_ref_lens = (
        spike_coverage_df[~spike_coverage_df["Consensus"].isin(["-", "N", "a", "c", "t", "g"])]
        .groupby(["Sample", "Reference_Name"])
        .agg({"Sample": "count"})
        .rename(columns={"Sample": "spikemaplen"})
        .reset_index()
        )
        spike_coverage_df = spike_coverage_df.groupby(["Sample", "Reference_Name"]).agg({"Coverage Depth": "median"}).reset_index().rename(
            columns={"Coverage Depth": "Spike Median Coverage", "Reference_Name": "Reference"}
        )
        spike_coverage_df["Spike Median Coverage"] = spike_coverage_df[["Spike Median Coverage"]].applymap(lambda x: f"{x:.0f}").astype(float)
        spike_cov_ref_lens["% Spike Covered"] = spike_cov_ref_lens.apply(
            lambda x: perc_len(x["spikemaplen"], "spike", ref_lens), axis=1
        )
        spike_cov_ref_lens["% Spike Covered"] = (
            spike_cov_ref_lens["% Spike Covered"].map(lambda x: f"{x:.2f}").astype(float)
            )
        spike_cov_ref_lens = spike_cov_ref_lens[
        ["Sample", "Reference_Name", "% Spike Covered"]].rename(columns={"Reference_Name": "Reference"})
    coverage_df = (
        coverage_df.groupby(["Sample", "Reference_Name"])
        .agg({"Coverage Depth": "median"})
        .reset_index()
        .rename(
            columns={"Coverage Depth": "Median Coverage", "Reference_Name": "Reference"}
        )
    )
    coverage_df["Median Coverage"] = (
        coverage_df[["Median Coverage"]].applymap(lambda x: f"{x:.0f}").astype(float)
    )
    summary_df = (
        reads_df.merge(cov_ref_lens, "left")
        .merge(coverage_df, "left")
        .merge(alleles_df, "left")
        .merge(indels_df, "left")
        .merge(allsamples_df, "outer", on="Sample")
    )
    if "sc2" in virus and "spike" not in virus:
        summary_df = (
            summary_df.merge(spike_coverage_df, "left")
            .merge(spike_cov_ref_lens, "left")
        )
    summary_df["Reference"] = summary_df["Reference"].fillna("")
    summary_df = summary_df.fillna(0)
    return summary_df


def flu_dais_modifier(vtype_df, dais_seq_df, irma_summary_df):
    tmp = (
        vtype_df.groupby(["Sample", "vtype"])
        .count()
        .reset_index()
        .groupby(["Sample"])["vtype"]
        .max()
        .reset_index()
    )
    vtype_dic = dict(zip(tmp.Sample, tmp.vtype))
    dais_seq_df["Target_ref"] = dais_seq_df["Sample"].apply(
        lambda x: irma2pandas.flu_segs[vtype_dic[x[:-2]]][x[-1]]
    )
    dais_seq_df["Sample"] = dais_seq_df["Sample"].str[:-2]
    dais_seq_df["Reference"] = dais_seq_df.apply(
        lambda x: which_ref(
            x["Sample"], x["Target_ref"], ref_proteins, irma_summary_df
        ),
        axis=1,
    )
    return dais_seq_df


def noref(ref):
    if str(ref) == "":
        return "N/A"
    else:
        return ref


def generate_dfs(irma_path):
    print("Building coverage_df")
    coverage_df = irma2pandas.dash_irma_coverage_df(irma_path)
    with open(f"./coverage.json", "w") as out:
        coverage_df.to_json(out, orient="split", double_precision=3)
        print(f"  -> coverage_df saved to {out.name}")
    print("Building read_df")
    read_df = irma2pandas.dash_irma_reads_df(irma_path)
    with open(f"./reads.json", "w") as out:
        read_df.to_json(out, orient="split", double_precision=3)
        print(f"  -> read_df saved to {out.name}")
    print("Build vtype_df")
    vtype_df = irma2pandas.dash_irma_sample_type(read_df)
    # Get most common vtype/sample
    with open(f"./vtype.json", "w") as out:
        vtype_df.to_json(out, orient="split", double_precision=3)
        print(f"  -> vtype_df saved to {out.name}")
    print("Building alleles_df")
    alleles_df = irma2pandas.dash_irma_alleles_df(irma_path)
    alleles_df = alleles_df[alleles_df["Minority Frequency"] >= 0.05]
    with open(f"./alleles.json", "w") as out:
        alleles_df.to_json(out, orient="split", double_precision=3)
        print(f"  -> alleles_df saved to {out.name}")
    print("Building indels_df")
    indels_df = irma2pandas.dash_irma_indels_df(irma_path)
    indels_df = indels_df[indels_df["Frequency"] >= 0.2]
    with open(f"./indels.json", "w") as out:
        indels_df.to_json(out, orient="split", double_precision=3)
        print(f"  -> indels_df saved to {out.name}")
    print("Building ref_data")
    ref_lens = irma2pandas.reference_lens(irma_path)
    segments, segset, segcolor = irma2pandas.returnSegData(coverage_df)
    with open(f"./ref_data.json", "w") as out:
        json.dump(
            {
                "ref_lens": ref_lens,
                "segments": segments,
                "segset": segset,
                "segcolor": segcolor,
            },
            out,
        )
        print(f"  -> ref_data saved to {out.name}")
    print("Building dais_vars_df")
    # Wait up to 60 seconds for dais_results to be available
    c = 0
    while c < 60:
        if len(glob(f"{irma_path}/dais_results/*seq")) == 0:
            time.sleep(1)
        c += 1
    dais_vars_df = dais2pandas.compute_dais_variants(work_path,f"{irma_path}/aggregate_outputs/dais-ribosome")
    with open(f"./dais_vars.json", "w") as out:
        dais_vars_df.to_json(out, orient="split", double_precision=3)
        print(f"  -> dais_vars_df saved to {out.name}")
    print("Building irma_summary_df")
    irma_summary_df = irma_summary(
        irma_path, samplesheet, read_df, indels_df, alleles_df, coverage_df, ref_lens
    )
    print("Building nt_sequence_df")
    nt_seqs_df = irma2pandas.dash_irma_sequence_df(
        irma_path, pad=qc_values[qc_plat_vir]["padded_consensus"]
    )
    if virus == "flu":
        nt_seqs_df = flu_dais_modifier(vtype_df, nt_seqs_df, irma_summary_df)
    else:
        nt_seqs_df = nt_seqs_df.merge(
            irma_summary_df[["Sample", "Reference"]], how="left", on=["Sample"]
        )
    print("Building pass_fail_df")
    pass_fail_df = pass_fail_qc_df(irma_summary_df, dais_vars_df, nt_seqs_df)
    with open(f"./pass_fail_qc.json", "w") as out:
        pass_fail_df.to_json(out, orient="split", double_precision=3)
        print(f"  -> pass_fail_qc_df saved to {out.name}")
    pass_fail_seqs_df = (
        pass_fail_df.reset_index()
        .melt(id_vars="Sample")
        .merge(nt_seqs_df, how="left", on=["Sample", "Reference"])
        .rename(columns={"value": "Reasons"})
    )
    # Print nt sequence fastas
    ## Exclude HA/NA/S premature stop sequences for Illumina
    if "ont" not in virus:
        if "flu" in virus:
            passed_df = pass_fail_seqs_df.loc[
        (pass_fail_seqs_df["Reasons"] == "Pass")
        | (
            (pass_fail_seqs_df["Reasons"].str.contains("Premature stop codon"))
            & (~pass_fail_seqs_df["Reasons"].str.contains(";", na=False))
            & (~pass_fail_seqs_df["Reference"].str.contains(r"'[H|N]A'"))
        )]
        elif "sc2" in virus:
            passed_df = pass_fail_seqs_df.loc[
        (pass_fail_seqs_df["Reasons"] == "Pass")
        | (
            (pass_fail_seqs_df["Reasons"].str.contains("Premature stop codon"))
            & (~pass_fail_seqs_df["Reasons"].str.contains(";", na=False))
            & (~pass_fail_seqs_df["Reference"].str.contains(r"'S'")) )
    ]
        elif "rsv" in virus:
            passed_df = pass_fail_seqs_df.loc[
        (pass_fail_seqs_df["Reasons"] == "Pass")
        | (
            (pass_fail_seqs_df["Reasons"].str.contains("Premature stop codon"))
            & (~pass_fail_seqs_df["Reasons"].str.contains(";", na=False))
            & (~pass_fail_seqs_df["Reference"].str.contains(r"'[F|G]'")) ) ]
    else:
        passed_df = pass_fail_seqs_df.loc[
        (pass_fail_seqs_df["Reasons"] == "Pass")
        | (
            (pass_fail_seqs_df["Reasons"].str.contains("Premature stop codon"))
            & (~pass_fail_seqs_df["Reasons"].str.contains(";", na=False))
        )
        ]
    passed_df.apply(
        lambda x: seq_df2fastas(
            irma_path,
            x["Sample"],
            x["Reference"],
            x["Sequence"],
            "nt",
            output_name="amended_consensus.fasta",
        ),
        axis=1,
    )
    failed_df = pass_fail_seqs_df[pass_fail_seqs_df.isin(passed_df) == False].dropna()
    failed_df["Reasons"] = failed_df["Reasons"].replace(r"\{.+\}", "", regex=True)
    failed_df.apply(
        lambda x: seq_df2fastas(
            irma_path,
            x["Sample"],
            x["Reference"],
            x["Sequence"],
            "nt",
            output_name="failed_amended_consensus.fasta",
            failed_reason=x["Reasons"],
        ),
        axis=1,
    )
    # Wait up to 60 seconds for dais_results to be available
    c = 0
    while c < 60:
        if len(glob(f"{irma_path}/aggregate_outputs/dais-ribosome/*seq")) == 0:
            time.sleep(1)
        c += 1
    aa_seqs_df = dais2pandas.seq_df(f"{irma_path}/aggregate_outputs/dais-ribosome")
    aa_seqs_df["Sample"] = aa_seqs_df["Sample"].astype(str)
    if virus == "flu":
        aa_seqs_df = flu_dais_modifier(vtype_df, aa_seqs_df, irma_summary_df)
    aa_seqs_df["Reference"] = aa_seqs_df.apply(
        lambda x: which_ref(x["Sample"], x["Protein"], ref_proteins, irma_summary_df),
        axis=1,
    )
    pass_fail_aa_df = (
        pass_fail_df.astype(str).reset_index()
        .melt(id_vars="Sample")
        .merge(aa_seqs_df.astype(str), how="left", on=["Sample", "Reference"])
        .rename(columns={"value": "Reasons"})
    )
    # Print aa sequence fastas
    passed_df = pass_fail_aa_df.loc[
        (
            (pass_fail_aa_df["Reasons"] == "Pass")
            | (
                (pass_fail_aa_df["Reasons"].str.contains("Premature stop codon"))
                & (~pass_fail_aa_df["Reasons"].str.contains(";", na=False))
            )
        )
    ]
    passed_df.apply(
        lambda x: seq_df2fastas(
            irma_path,
            x["Sample"],
            x["Protein"],
            x["AA Sequence"],
            "aa",
            output_name="amino_acid_consensus.fasta",
        ),
        axis=1,
    )
    failed_df = pass_fail_aa_df[pass_fail_aa_df.isin(passed_df) == False].dropna()
    failed_df["Reasons"] = failed_df["Reasons"].replace(r"\{.+\}", "", regex=True)
    failed_df.apply(
        lambda x: seq_df2fastas(
            irma_path,
            x["Sample"],
            x["Protein"],
            x["AA Sequence"],
            "aa",
            output_name="failed_amino_acid_consensus.fasta",
            failed_reason=x["Reasons"],
        ),
        axis=1,
    )
    with open(f"./nt_sequences.json", "w") as out:
        nt_seqs_df.to_json(out, orient="split")
        print(f"  -> nt_sequence_df saved to {out.name}")
    irma_summary_df = irma_summary_df.merge(
        pass_fail_df.reset_index().melt(id_vars=["Sample"], value_name="Reasons"),
        how="left",
        on=["Sample", "Reference"],
    )
    irma_summary_df["Reference"] = irma_summary_df["Reference"].apply(
        lambda x: noref(x)
    )
    irma_summary_df["Reasons"] = irma_summary_df["Reasons"].fillna("Fail")
    irma_summary_df = irma_summary_df.rename(columns={"Reasons": "Pass/Fail Reason"})
    irma_summary_df["MIRA module"] = version_module()
    with open(f"./irma_summary.json", "w") as out:
        irma_summary_df.to_json(out, orient="split", double_precision=3)
        print(f"  -> irma_summary_df saved to {out.name}")
    return read_df, coverage_df, segments, segcolor, pass_fail_df


def seq_df2fastas(
    irma_path,
    sample,
    reference,
    sequence,
    nt_or_aa,
    output_name=False,
    failed_reason="",
):
    if not output_name:
        output_name = f"{nt_or_aa}_{sample}_{reference}.fasta"
    if failed_reason != "":
        failed_reason = f"|{failed_reason}"
    with open(f"./{output_name}", "a+") as out:
        print(f">{sample}|{reference}{failed_reason}\n{sequence}", file=out)


###################################################################
# Figures
###################################################################


def pivot4heatmap(coverage_df):
    if "Coverage_Depth" in coverage_df.columns:
        cov_header = "Coverage_Depth"
    else:
        cov_header = "Coverage Depth"
    if virus.lower() == "sc2-spike":
        coverage_df = coverage_df[coverage_df["HMM_Position"].between(21563, 25384)]
    df2 = coverage_df[["Sample", "Reference_Name", cov_header]]
    df3 = df2.groupby(["Sample", "Reference_Name"]).median().reset_index()
    try:
        df3[["Subtype", "Segment", "Group"]] = df3["Reference_Name"].str.split(
            "_", expand=True
        )
    except ValueError:
        df3["Segment"] = df3["Reference_Name"]
    df4 = df3[["Sample", "Segment", cov_header]]
    return df4


def createheatmap(irma_path, coverage_medians_df):
    print(f"Building coverage heatmap")
    if "Coverage_Depth" in coverage_medians_df.columns:
        cov_header = "Coverage_Depth"
    else:
        cov_header = "Coverage Depth"
    coverage_medians_df = (
        coverage_medians_df.pivot(index="Sample", columns="Segment")
        .fillna(0)
        .reset_index()
        .melt(id_vars="Sample")#, value_name=cov_header)
        .drop([None], axis=1)
    )
    coverage_medians_df = coverage_medians_df.rename(columns={"value": cov_header})
    if virus == "rsv":
        coverage_medians_df = coverage_medians_df.replace("RSV_AD", "RSV").replace("RSV_BD", "RSV").replace("RSV_A","RSV").replace("RSV_B","RSV")
        coverage_medians_df = coverage_medians_df.sort_values(
            by=["Sample", "Segment", "Coverage Depth"], ascending=False
        ).drop_duplicates(subset=["Sample"], keep="first")
    cov_max = coverage_medians_df[cov_header].max()
    if cov_max <= 200:
        cov_max = 200
    elif cov_max >= 1000:
        cov_max = 1000
    fig = go.Figure(
        data=go.Heatmap(  # px.imshow(df5
            x=list(coverage_medians_df["Sample"]),
            y=list(coverage_medians_df["Segment"]),
            z=list(coverage_medians_df[cov_header]),
            zmin=0,
            zmid=100,
            zmax=cov_max,
            colorscale="gnbu",
            hovertemplate="%{y} = %{z:,.0f}x<extra>%{x}<br></extra>",
        )
    )
    fig.update_layout(legend=dict(x=0.4, y=1.2, orientation="h"))
    fig.update_xaxes(side="top")
    pio.write_json(fig, f"./heatmap.json")
    print(f"  -> coverage heatmap json saved to ./heatmap.json")


def assign_number(reason):
    if reason == "No assembly":
        print(f"reason={reason} | number={4}")
        return 4
    elif reason == "Pass":
        print(f"reason={reason} | number={-4}")
        return -4  # numpy.nan
    elif len(reason.split(";")) > 1:
        print(f"reason={reason} | number={len(reason.split(';'))}")
        return len(reason.split(";"))
    else:  # reason == "Premature stop codon":
        print(f"reason={reason} | number={-1}")
        return -1


def create_passfail_heatmap(irma_path, pass_fail_df):
    print("Building pass_fail_heatmap")
    if virus == "flu" or virus == "rsv":
        pass_fail_df = (
            pass_fail_df.fillna("z")
            .reset_index()
            .melt(id_vars=["Sample"], value_name="Reasons")
        )
        if virus == "flu":
            pass_fail_df["Reference"] = pass_fail_df["Reference"].apply(
            lambda x: x.split("_")[1]
            )
        if virus == "rsv":
            pass_fail_df["Reference"] = pass_fail_df["Reference"].apply(
            lambda x: x.replace("_AD", "").replace("_BD", "").replace("_A","").replace("_B","")
            )
        pass_fail_df = pass_fail_df.sort_values(
            by=["Sample", "Reference", "Reasons"], ascending=True
        ).drop_duplicates(subset=["Sample", "Reference"], keep="first")
        pass_fail_df["Reasons"] = pass_fail_df["Reasons"].replace("z", "No assembly")
        pass_fail_df["Reasons"] = pass_fail_df["Reasons"].replace(
            r"\{.+\}", "", regex=True
        )
    else:
        pass_fail_df = (
            pass_fail_df.fillna("No assembly")
            .reset_index()
            .melt(id_vars=["Sample"], value_name="Reasons")
        )
    pass_fail_df = pass_fail_df.dropna()
    pass_fail_df["Number"] = pass_fail_df["Reasons"].apply(lambda x: assign_number(x))
    pass_fail_df["Reasons"].fillna("No assembly")
    fig = go.Figure(
        data=go.Heatmap(
            x=list(pass_fail_df["Sample"]),
            y=list(pass_fail_df["Reference"]),
            z=list(pass_fail_df["Number"]),
            customdata=list(pass_fail_df["Reasons"]),
            zmin=-4,
            zmax=6,
            zmid=1,
            colorscale="blackbody_r",  # 'ylorrd',
            hovertemplate="%{x}<br>%{customdata}<extra>%{y}<br></extra>",
        )
    )
    fig.update_xaxes(side="top")
    fig.update_traces(showscale=False)
    fig.update_layout(paper_bgcolor="white", plot_bgcolor="white")
    pio.write_json(fig, f"./pass_fail_heatmap.json")
    print(f"  -> pass_fail heatmap json saved to ./pass_fail_heatmap.json")


def createsankey(irma_path, read_df, virus):
    print(f"Building read sankey plot")
    for sample in read_df["Sample"].unique():
        sankeyfig = irma2pandas.dash_reads_to_sankey(
            read_df[read_df["Sample"] == sample], virus
        )
        pio.write_json(sankeyfig, f"./readsfig_{sample}.json")
        print(f"  -> read sankey plot json saved to ./readsfig_{sample}.json")


def createReadPieFigure(irma_path, read_df):
    print(f"Building barcode distribution pie figure")
    read_df = read_df[read_df["Record"] == "1-initial"]
    fig = px.pie(read_df, values="Reads", names="Sample")
    fig.update_traces(textposition="inside", textinfo="percent+label")
    fig.write_json(f"./barcode_distribution.json")
    print(f"  -> barcode distribution pie figure saved to ./barcode_distribution.json")


def zerolift(x):
    if x == 0:
        return 0.000000000001
    return x


def createSampleCoverageFig(sample, df, segments, segcolor, cov_linear_y):
    if virus == "rsv":
        df=df.dropna()
    if "Coverage_Depth" in df.columns:
        cov_header = "Coverage_Depth"
    else:
        cov_header = "Coverage Depth"
    if "HMM_Position" in df.columns:
        pos_header = "HMM_Position"
    else:
        pos_header = "Position"
    if not cov_linear_y:
        df[cov_header] = df[cov_header].apply(lambda x: zerolift(x))
    df2 = df[df["Sample"] == sample]
    fig = go.Figure()
    if "SARS-CoV-2" in segments or "RSV_A" in segments or "RSV_B" in segments or "RSV_AD" in segments or "RSV_BD" in segments:
        # y positions for gene boxes
        oy = (
            max(df2[cov_header]) / 10
        )  # This value determines where the top of the ORF box is drawn against the y-axis
        if not cov_linear_y:
            ya = 0.9
        else:
            ya = 0 - (max(df2[cov_header]) / 20)
        if "SARS-CoV-2" in segments:
            orf_pos = {
            "orf1ab": (266, 21556),
            "S": [21563, 25385],
            "ORF3a": [25393, 26221],
            "E": [26245, 26473],
            "M": [26523, 27192],
            "ORF6": [27202, 27388],
            "ORF7a": [27394, 27759],
            "ORF7b": [27756, 27887],
            "ORF8": [27894, 28260],
            "N": [28274, 29534],
            "ORF10": [29558, 29675],
            "ORF9b": [28284, 28577],
            }
        elif "RSV_AD" in segments:
            orf_pos = {
                "NS1": [99,518],
                "NS2": [628,1002],
                "N": [1140,2315],
                "P": [2347,3072],
                "M": [3255,4025],
                "SH": [4295, 4489],
                "G": [4681,5646],
                "F": [5726,7450],
                "M2-1": [7669,8253],
                "M2-2": [8228,8494],
                "L": [8561,15058]
            }
        elif "RSV_BD" in segments:
            orf_pos = {
                "NS1": [100,519],
                "NS2": [627,1001],
                "N": [1140,2315],
                "P": [2348,3073],
                "M": [3263,4033],
                "SH": [4302,4499],
                "G": [4689,5621],
                "F": [5719,7443],
                "M2-1": [7670,8257],
                "M2-2": [8223,8495],
                "L": [8561,15061]
            }
        elif "RSV_B" in segments:
            orf_pos = {
                "NS1": [99,518],
                "NS2": [626,1000],
                "N": [1140,2315],
                "P": [2348,3073],
                "M": [3263,4033],
                "SH": [4303,4500],
                "G": [4690,5589],
                "F": [5666,7390],
                "M2-1": [7618,8205],
                "M2-2": [8171,8443],
                "L": [8509,15009]
            }
        elif "RSV_A" in segments:
            orf_pos = {
                "NS1": [99,518],
                "NS2": [628,1002],
                "N": [1141,2316],
                "P": [2347,3072],
                "M": [3262,4032],
                "SH": [4304,4498],
                "G": [4689,5585],
                "F": [5662,7386],
                "M2-1": [7607,8191],
                "M2-2": [8160,8432],
                "L": [8499,14996]
            }
            
        #add B (nonD)
        color_index = 0
        #print(orf_pos)
        for orf, pos in orf_pos.items():
            fig.add_trace(
                go.Scatter(
                    x=[pos[0], pos[1], pos[1], pos[0], pos[0]],
                    y=[oy, oy, 0, 0, oy],
                    fill="toself",
                    fillcolor=px.colors.qualitative.Set3[color_index],
                    line=dict(color=px.colors.qualitative.Set3[color_index]),
                    mode="lines",
                    name=orf,
                    opacity=0.8,
                )
            )
            color_index += 1
    for g in segments:
        if g in df2["Reference_Name"].unique():
            try:
                g_base = g.split("_")[1]
            except IndexError:
                g_base = g
            df3 = df2[df2["Reference_Name"] == g]
            fig.add_trace(
                go.Scatter(
                    x=df3[pos_header],
                    y=df3[cov_header],
                    mode="lines",
                    line=go.scatter.Line(color=segcolor[g_base]),
                    name=g,
                    customdata=tuple(["all"] * len(df3["Sample"])),
                )
            )
    fig.add_shape(
        type="line",
        x0=0,
        x1=df2[pos_header].max(),
        y0=qc_values[qc_plat_vir]["med_cov"],
        y1=qc_values[qc_plat_vir]["med_cov"],
        line=dict(color="Black", dash="dash", width=5),
    )
    ymax = df2[cov_header].max()
    if not cov_linear_y:
        ya_type = "log"
        ymax = ymax ** (1 / 10)
    else:
        ya_type = "linear"
    fig.update_layout(
        height=600,
        title=sample,
        yaxis_title="Coverage",
        xaxis_title="Reference Position",
        yaxis_type=ya_type,
        yaxis_range=[0, ymax],
    )
    return fig


def createcoverageplot(irma_path, coverage_df, segments, segcolor):
    samples = coverage_df["Sample"].unique()
    print(f"Building coverage plots for {len(samples)} samples")
    for sample in samples:
        coveragefig = createSampleCoverageFig(
            sample, coverage_df, segments, segcolor, True
        )
        pio.write_json(coveragefig, f"./coveragefig_{sample}_linear.json")
        print(f"  -> saved ./coveragefig_{sample}_linear.json")
    print(f" --> All coverage jsons saved")


def generate_figs(irma_path, read_df, coverage_df, segments, segcolor, pass_fail_df):
    createReadPieFigure(irma_path, read_df)
    createsankey(irma_path, read_df, virus)
    createheatmap(irma_path, pivot4heatmap(coverage_df))
    create_passfail_heatmap(irma_path, pass_fail_df)
    createcoverageplot(irma_path, coverage_df, segments, segcolor)


if __name__ == "__main__":
    generate_figs(irma_path, *generate_dfs(irma_path))
