import pandas as pd
from os.path import dirname, basename, isfile
from glob import glob
import plotly.express as px
from re import findall
import plotly.graph_objects as go

def seg(s):
    return findall(r"HA|NA|MP|NP|NS|PA|PB1|PB2|SARS-CoV-2|AD|BD|A|B", s) 

def returnStageColors(df):
    df = df[df["Stage"].isin([4, 5])]
    recs = list(set([seg(i)[0] for i in list(df["Record"])]))
    reccolor = {}
    for i in range(0, len(recs)):
        reccolor[recs[i]] = px.colors.qualitative.G10[i]
    return reccolor


def dash_reads_to_sankey(df, virus):
    df = df[df["Stage"] != 0]
    reccolor = returnStageColors(df)
    labels = list(df["Record"])
    x_pos, y_pos, color = [], [], []
    for i in labels:
        if i[0] == "1":
            x_pos.append(0.05)
            y_pos.append(0.1)
            color.append("#8A8A8A")
        elif i[0] == "2":
            x_pos.append(0.2)
            y_pos.append(0.1)
            color.append("#8A8A8A")
        elif i[0] == "3":
            x_pos.append(0.35)
            y_pos.append(0.1)
            color.append("#8A8A8A")
        else:
            x_pos.append(0.95)
            y_pos.append(0.01)
            color.append(reccolor[seg(i)[0]])
    source, target, value = [], [], []
    for index, row in df.iterrows():
        if row["Stage"] == 4 or row["Stage"] == 5:
            source.append(labels.index("3-match"))
            target.append(labels.index(row["Record"]))
            value.append(row["Reads"])
        elif row["Stage"] == 3:
            source.append(labels.index("2-passQC"))
            target.append(labels.index(row["Record"]))
            value.append(row["Reads"])
        elif row["Stage"] == 2:
            source.append(labels.index("1-initial"))
            target.append(labels.index(row["Record"]))
            value.append(row["Reads"])
    if 'sc2' in virus or 'rsv' in virus:
        arrangement = "freeform"
    else:
        arrangement = "snap"
    fig = go.Figure(
        data=[
            go.Sankey(
                arrangement=arrangement,
                node=dict(
                    pad=15,
                    thickness=20,
                    label=labels,
                    x=x_pos,
                    y=y_pos,
                    color=color,
                    hovertemplate="%{label} %{value} reads <extra></extra>",
                ),
                link=dict(
                    source=source,
                    target=target,
                    value=value,
                    color=color[1:],
                    hovertemplate="<extra></extra>",
                ),
            )
        ]
    )
    return fig


def irmatable2df(irmaFiles):
    df = pd.DataFrame()
    for f in irmaFiles:
        sample = basename(dirname(dirname(f)))
        if "insertions" not in f:
            df_prime = pd.read_csv(f, sep="\t", index_col=False)
        else:
            df_prime = pd.read_csv(f, sep="\s+", index_col=False)
        df_prime.insert(loc=0, column="Sample", value=sample)
        df = pd.concat([df, df_prime])
    return df


def dash_irma_reads_df(irma_path):
    readFiles = glob(irma_path + "/*/IRMA/*/tables/READ_COUNTS.txt")
    df = pd.DataFrame()
    df = irmatable2df(readFiles)
    df["Stage"] = df["Record"].apply(lambda x: int(x.split("-")[0]))
    return df

def read_record2type(record):
    try:
        vtype, ref = record.split('_')[0:2]
        vtype = vtype[2:]
        if ref in ['HA', 'NA']:
            subtype = record.split('_')[-1]
        else:
            subtype = ''
        return [vtype, ref, subtype]
    except ValueError as E:
        return [record[2:]]*3

def dash_irma_sample_type(reads_df):
    type_df = reads_df[reads_df['Record'].str[0] == '4']
    new_cols = ['vtype', 'ref_type', 'subtype']
    for n, cols in enumerate(new_cols):
        type_df[cols] = type_df['Record'].apply(lambda x: read_record2type(x)[n])
    type_df['Reference'] = type_df['Record'].apply(lambda x: x.split('_')[0][2:])
    type_df = type_df[["Sample", "vtype", "ref_type", "subtype"]]
    return type_df

flu_segs = {'A':{'1':'PB2','2':'PB1','3':'PA','4':'HA','5':'NP','6':'NA','7':'M','8':'NS'}, 
    'B':{'1':'PB1','2':'PB2','3':'PA','4':'HA','5':'NP','6':'NA','7':'M','8':'NS'}}

def dash_irma_sequence_df(irma_path, amended=True, pad=True):
    if amended:
        if pad:
            sequenceFiles = glob(irma_path + "/*/IRMA/*/amended_consensus/*pad.fa")
        else:
            sequenceFiles = [i for i in glob(irma_path + "/*/IRMA/*/amended_consensus/*fa") if 'pad' not in i]
    else:
        sequenceFiles = [i for i in glob(irma_path + "/*/IRMA/*/*fasta") if 'pad' not in i]
    df = pd.DataFrame(columns=["Sample", "Sequence"])
    for f in sequenceFiles:
        content = open(f).read()
        for s in findall(r">.+", content):
            sample_id, sequence = s[1:], findall(rf"(?s)(?<={s}).+(?=>)*", content)[0].replace('\n','')
            df = pd.concat([df, pd.DataFrame([[sample_id, sequence]], columns=df.columns)])
    return df


def dash_irma_coverage_df(irma_path):
    coverageFiles = glob(irma_path + "/*/IRMA/*/tables/*a2m.txt")
    # a2msamples = [i.split('/')[-3] for i in coverageFiles]
    # otherFiles = [i for i in glob(irma_path+'/*/tables/*coverage.txt')]
    if len(coverageFiles) == 0:
        coverageFiles = glob(irma_path + "/*/IRMA/*/tables/*coverage.txt")
    if len(coverageFiles) == 0:
        return "No coverage files found under {}/*/IRMA/*/tables/".format(irma_path)
    df = irmatable2df(coverageFiles)

    return df


def dash_irma_alleles_df(irma_path, full=False):
    alleleFiles = glob(irma_path + "/*/IRMA/*/tables/*variants.txt")
    df = irmatable2df(alleleFiles)
    if not full:
        if "HMM_Position" in df.columns:
            ref_heads = [
                "Sample",
                "Reference_Name",
                "HMM_Position",
                "Position",
                "Total",
                "Consensus_Allele",
                "Minority_Allele",
                "Consensus_Count",
                "Minority_Count",
                "Minority_Frequency",
            ]
        else:
            ref_heads = [
                "Sample",
                "Reference_Name",
                "Position",
                "Total",
                "Consensus_Allele",
                "Minority_Allele",
                "Consensus_Count",
                "Minority_Count",
                "Minority_Frequency",
            ]
        df = df[ref_heads]
        df = df.rename(
            columns={
                "Reference_Name": "Reference",
                "HMM_Position": "Reference Position",
                "Position": "Sample Position",
                "Total": "Coverage",
                "Consensus_Allele": "Consensus Allele",
                "Minority_Allele": "Minority Allele",
                "Consensus_Count": "Consensus Count",
                "Minority_Count": "Minority Count",
                "Minority_Frequency": "Minority Frequency",
            }
        )
        df["Minority Frequency"] = df[["Minority Frequency"]].applymap(
            lambda x: float(f"{float(x):.{3}f}")
        )
        df["Sample"] = df[["Sample"]].astype(str)
    return df


def dash_irma_indels_df(irma_path, full=False):
    insertionFiles = glob(irma_path + "/*/IRMA/*/tables/*insertions.txt")
    deletionFiles = glob(irma_path + "/*/IRMA/*/tables/*deletions.txt")
    idf = irmatable2df(insertionFiles)
    idf['Length'] = idf['Insert'].str.len()
    ddf = irmatable2df(deletionFiles)
    df = pd.concat([idf, ddf])
    if "HMM_Position" in df.columns:
        df = df.rename(
            columns={
                "Reference_Name": "Reference",
                "Upstream_Position": "Sample - Upstream Position",
                "HMM_Position": "Reference - Upstream Position",
                "Total": "Upstream Base Coverage",
            }
        )
        df = df[
            [
                "Sample",
                "Sample - Upstream Position",
                "Reference",
                "Reference - Upstream Position",
                "Context",
                "Length",
                "Insert",
                "Count",
                "Upstream Base Coverage",
                "Frequency",
            ]
        ]
    else:
        df = df.rename(
            columns={
                "Reference_Name": "Reference",
                "Upstream_Position": "Sample - Upstream Position",
                "Total": "Upstream Base Coverage",
            }
        )
        df = df[
            [
                "Sample",
                "Sample - Upstream Position",
                "Reference",
                "Context",
                "Length",
                "Insert",
                "Count",
                "Upstream Base Coverage",
                "Frequency",
            ]
        ]
    df["Frequency"] = df[["Frequency"]].applymap(lambda x: float(f"{float(x):.{3}f}"))
    df["Sample"] = df[["Sample"]].astype(str)
    return df


def reference_lens(irma_path):
    reffiles = glob(irma_path + "/*/IRMA/*/intermediate/0-ITERATIVE-REFERENCES/R0*ref")
    ref_lens = {}
    for f in reffiles:
        ref = basename(f)[3:-4]
        if ref not in ref_lens.keys():
            with open(f, "r") as d:
                seq = ""
                for line in d:
                    if not line[0] == ">":
                        seq += line.strip()
            ref_lens[ref] = len(seq)
    return ref_lens


def returnSegData(df):
    segments = list(df["Reference_Name"].unique())
    try:
        segset = [i.split("_")[1] for i in segments]
    except IndexError:
        segset = segments
    segset = list(set(segset))
    segcolor = {}
    for i in range(0, len(segset)):
        segcolor[segset[i]] = px.colors.qualitative.G10[i]
    return segments, segset, segcolor