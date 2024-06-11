#!/usr/bin/env python
#K. A. Lacek
# Jan 2024

# Functional for samplesheet, irma summary, alleles, indels
import pandas as pd
import argparse
from pathlib import Path
import pyarrow as pa
import pyarrow.parquet as pq
from os.path import dirname, basename, isfile
from glob import glob

parser = argparse.ArgumentParser()
parser.add_argument("-p", "--path", help="the file path to where the IRMA folder is located")
parser.add_argument("-f", "--file", help="input file for conversion to CDP-compatible parquet. If empty, script creates reads table, coverage table, and all alleles table with filenames inferred from runid")
parser.add_argument("-o", "--outputname", help="name of parquet output file")
parser.add_argument("-r", "--runid", help="runid name, if empty: runid is the name of the directory in which the script is run")
parser.add_argument("-i", "--instrument", help="sequencing instrument name. If empty, testInstrument")

inputarguments = parser.parse_args()

if inputarguments.path:
    wd_path = inputarguments.path
else:
    wd_path = Path.cwd()

if inputarguments.file:
    infi = inputarguments.file
else:
    infi = ''

if inputarguments.outputname:
    outfi = inputarguments.outputname
else:
    outfi = ''

if inputarguments.runid:
    run_id = inputarguments.runid
else:
    run_id = Path.cwd()
    run_id = str(run_id).split('/')[-1]

if inputarguments.instrument:
    instrument = inputarguments.instrument
else:
    instrument = "testInstrument"

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

def irma_reads_df(irma_path):
    readFiles = glob(irma_path + "/*/tables/READ_COUNTS.txt")
    df = pd.DataFrame()
    df = irmatable2df(readFiles)
    df["Stage"] = df["Record"].apply(lambda x: int(x.split("-")[0]))
    return df

def irma_coverage_df(irma_path):
    coverageFiles = glob(irma_path + "/*/tables/*a2m.txt")
    # a2msamples = [i.split('/')[-3] for i in coverageFiles]
    # otherFiles = [i for i in glob(irma_path+'/*/tables/*coverage.txt')]
    if len(coverageFiles) == 0:
        coverageFiles = glob(irma_path + "/*/tables/*coverage.txt")
    if len(coverageFiles) == 0:
        return "No coverage files found under {}/*/tables/".format(irma_path)
    df = irmatable2df(coverageFiles)

    return df

def irma_alleles_df(irma_path, full=False):
    alleleFiles = glob(irma_path + "/*/tables/*variants.txt")
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
    return df

#file I/O
def parquetify(table, outfi):
    pd.DataFrame.to_csv(table, "temp.csv", sep='\t', index=False, header=True)
    chunksize = 100_000
    # modified from https://stackoverflow.com/questions/26124417/how-to-convert-a-csv-file-to-parquet
    csv_stream = pd.read_csv("temp.csv", sep='\t', chunksize=chunksize, low_memory=False)
    for i, chunk in enumerate(csv_stream):
        print("Chunk", i)
        if i == 0:
        # Guess the schema of the CSV file from the first chunk
            parquet_schema = pa.Table.from_pandas(df=chunk).schema
        # Open a Parquet file for writing
            parquet_writer = pq.ParquetWriter(outfi, parquet_schema, compression='snappy', version='1.0')
    # Write CSV chunk to the parquet file
        table = pa.Table.from_pandas(chunk, schema=parquet_schema)
        parquet_writer.write_table(table)
        
    parquet_writer.close()

if ".csv" in infi:
    table = pd.read_csv(infi, header=0)
elif ".xls" in infi:
    table = pd.read_excel(infi, header=0, engine='openpyxl')
elif "run_info.txt" in infi:
    table = pd.read_csv(infi, sep="\t", header=0)
    table['runid'] = run_id
    table['instrument'] = instrument
    parquetify(table, outfi)
    exit()
elif ".txt" in infi or ".tsv" in infi:
    table = pd.read_csv(infi, sep="\t", header=0)

elif ".fasta" in infi:
    seq_dict = {}
    i = 0
    with open(infi, 'r') as infi:
        for line in infi:
            if line[0] == '>':
                i += 1
                key = line.strip('>').split('|')[0]
                segment = line.strip().split('|')[1]
                try:
                    qc_failure = line.strip().split('|')[2]
                except:
                    qc_failure = 'pass'
                seq_dict[i] = [key, segment, qc_failure]
            else:
                value = line.strip()
                seq_dict[i].append(value)
    table = pd.DataFrame.from_dict(seq_dict, orient='index', columns=["sample_id", "reference", "qc_decision", "sequence"])

elif infi == '':
    readstable = irma_reads_df(wd_path+'/IRMA')
    covtable = irma_coverage_df(wd_path+'/IRMA')
    allelestable = irma_alleles_df(wd_path+'/IRMA')
    for t in ([readstable, f"{run_id}_reads.parq"], [covtable, f"{run_id}_coverage.parq"], [allelestable, f"{run_id}_alleles.parq"]):
        t[0]['runid'] = run_id
        t[0]['instrument'] = instrument
        parquetify(t[0], t[1])
    exit()


table['runid'] = run_id

table['instrument'] = instrument

parquetify(table, outfi)

