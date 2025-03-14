#!/usr/bin/env python

# import yaml
from os.path import abspath
from sys import argv, exit
import pandas as pd
from glob import glob
import subprocess
import os
import argparse
import time

time.sleep(60)

parser = argparse.ArgumentParser()
parser.add_argument("-s", "--samplesheet", help="Samplesheet with sample names")
parser.add_argument(
    "-r",
    "--runid",
    help="Full path to data directory containing either a fastq_pass subdirectory for ONT data or fastq subdirectory for Illumina",
)
parser.add_argument(
    "-e",
    "--experiment_type",
    help="Experiment type options: Flu-ONT, SC2-Spike-Only-ONT, Flu-Illumina, SC2-Whole-Genome-ONT, SC2-Whole-Genome-Illumina",
)

inputarguments = parser.parse_args()

root = "/".join(abspath(__file__).split("/")[:-2])
if len(argv) < 2:
    exit(
        "\n\tUSAGE: {} -s <samplesheet.csv> -r <runpath> -e <experiment_type> <optional: -p primer_schema> <optional: -c clean_option> \n".format(
            __file__
        )
    )

print(f"argv[1:]= {argv[1:]}")
try:
    samplesheet = inputarguments.samplesheet
    runpath = inputarguments.runid
    if runpath[-1] == "/":
        runpath = runpath[:-1]
    experiment_type = inputarguments.experiment_type

except:
    parser.print_help()
    exit(0)

print(runpath)
print(samplesheet)

df = pd.read_csv(samplesheet)
dfd = df.to_dict("index")

data = "sample,barcodes,fastq_1,fastq_2,sample_type\n"
for d in dfd.values():
    id = d["Sample ID"]
    barcode = d["Barcode #"]
    print(f"Sample ID: {id}")
    print(f"Barcode: {barcode}")
    print (f"{runpath}/fastq_pass/cat_fastqs/{id}.fastq*")
    print (glob(f"{runpath}/fastq_pass/cat_fastqs/{id}.fastq*", recursive=True))
    fastq_1 = glob(f"{runpath}/fastq_pass/cat_fastqs/{id}.fastq*", recursive=True)[0]
    fastq_2 = ""
    sample_type = d["Sample Type"]
    if len(barcode) < 1:
        print(f"Fastqs not found for sample {id}")
        exit()
    else:
        data += f"{id},{barcode},{fastq_1},{fastq_2},{sample_type}\n"

with open("nextflow_samplesheet.csv", "w") as out:
    out.write(data)
