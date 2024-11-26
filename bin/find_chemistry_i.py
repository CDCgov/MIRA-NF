#!/usr/bin/env python

import argparse
import gzip

parser = argparse.ArgumentParser(
    description="Find chemistry information from fastq files and store into a csv used downstream."
)
parser.add_argument("-s", "--sample", required=True, help="Sample name")
parser.add_argument("-q", "--fastq", required=True, help="R1.fastq file path")
parser.add_argument("-r", "--runid", required=True, help="Run ID")
parser.add_argument("-e", "--exp_type", required=True, help="Exp type")
parser.add_argument("-p", "--wd_path", required=True, help="primer type")
parser.add_argument("-c", "--read_count", required=True, help="read counts")
parser.add_argument("-i", "--irma_config", required=True, help="custom irma config")

args = parser.parse_args()

sample = args.sample
fastq = args.fastq
runid = args.runid
exp_type = args.exp_type
wd_path = args.wd_path
config_path_flu = wd_path + "/bin/irma_config/FLU.sh"
config_path_flu_75 = wd_path + "/bin/irma_config/FLU-2x75.sh"
config_path_flu_sensitive = wd_path + "/bin/irma_config/FLU-sensitive.sh"
config_path_flu_secondary = wd_path + "/bin/irma_config/FLU-secondary.sh"
config_path_flu_utr = wd_path + "/bin/irma_config/FLU-utr.sh"
config_path_sc2_wgs_illumina = wd_path + "/bin/irma_config/CoV.sh"
config_path_sc2_wgs_illumina_75 = wd_path + "/bin/irma_config/SC2-2x75.sh"
config_path_rsv_illumina = wd_path + "/bin/irma_config/RSV.sh"
config_path_rsv_illumina_75 = wd_path + "/bin/irma_config/RSV-2x75.sh"
read_count = args.read_count
irma_config = args.irma_config

try:
    with open(fastq) as infi:
        contents = infi.readlines()
except:
    with gzip.open(fastq) as infi:
        contents = infi.readlines()

if irma_config == "none":
    if exp_type == "Flu-Illumina" and 145 <= len(contents[1]):
        irma_custom_0 = ""
        irma_custom_1 = f"--external-config {config_path_flu}"
        subsample = read_count
    elif exp_type == "Flu-Illumina" and 70 <= len(contents[1]) < 145:
        irma_custom_0 = ""
        irma_custom_1 = f"--external-config {config_path_flu_75}"
        subsample = read_count
    elif exp_type == "Flu-Illumina" and 0 < len(contents[1]) < 70:
        irma_custom_0 = ""
        irma_custom_1 = f"--external-config {config_path_flu_75}"
        subsample = read_count
    elif exp_type == "Flu-Illumina" and len(contents[1]) == 0:
        irma_custom_0 = ""
        irma_custom_1 = ""
        subsample = "0"
    elif exp_type == "SC2-Whole-Genome-Illumina" and len(contents[1]) > 80:
        irma_custom_0 = ""
        irma_custom_1 = f"--external-config {config_path_sc2_wgs_illumina}"
        subsample = read_count
    elif exp_type == "SC2-Whole-Genome-Illumina" and len(contents[1]) < 80:
        irma_custom_0 = ""
        irma_custom_1 = f"--external-config {config_path_sc2_wgs_illumina_75}"
        subsample = read_count
    elif exp_type == "SC2-Whole-Genome-Illumina" and len(contents[1]) == 0:
        irma_custom_0 = ""
        irma_custom_1 = ""
        subsample = "0"
    elif exp_type == "RSV-Illumina" and len(contents[1]) > 80:
        irma_custom_0 = ""
        irma_custom_1 = f"--external-config {config_path_rsv_illumina}"
        subsample = read_count
    elif exp_type == "RSV-Illumina" and len(contents[1]) < 80:
        irma_custom_0 = ""
        irma_custom_1 = f"--external-config {config_path_rsv_illumina_75}"
        subsample = read_count
    elif exp_type == "RSV-Illumina" and len(contents[1]) == 0:
        irma_custom_0 = ""
        irma_custom_1 = ""
        subsample = "0"
elif irma_config == "sensitive":
    irma_custom_0 = ""
    irma_custom_1 = f"--external-config {config_path_flu_sensitive}"
    subsample = read_count
elif irma_config == "secondary":
    irma_custom_0 = ""
    irma_custom_1 = f"--external-config {config_path_flu_secondary}"
    subsample = read_count
elif irma_config == "utr":
    irma_custom_0 = ""
    irma_custom_1 = f"--external-config {config_path_flu_utr}"
    subsample = read_count

if exp_type == "Flu-Illumina":
    IRMA_module = "FLU"
elif exp_type == "SC2-Whole-Genome-Illumina":
    IRMA_module = "CoV"
elif exp_type == "RSV-Illumina":
    IRMA_module = "RSV"

filename = f"{sample}_chemistry.csv"
headers = "sample_ID,irma_custom_0,irma_custom_1,subsample,irma_module\n"
with open(filename, "w") as file:
    file.write(
        headers
        + f"{sample},{irma_custom_0},{irma_custom_1},{subsample},{IRMA_module}\n"
    )
