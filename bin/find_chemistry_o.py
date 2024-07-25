import argparse
import gzip

parser = argparse.ArgumentParser(
    description="Find chemistry information from fastq files."
)
parser.add_argument("-s", "--sample", required=True, help="Sample name")
parser.add_argument("-q", "--fastq", required=True, help="R1.fastq file path")
parser.add_argument("-r", "--runid", required=True, help="Run ID")
parser.add_argument("-e", "--exp_type", required=True, help="Exp type")
parser.add_argument("-p", "--wd_path", required=True, help="Exp type")

args = parser.parse_args()

sample = args.sample
fastq = args.fastq
runid = args.runid
exp_type = args.exp_type
wd_path = args.wd_path
config_path_flu_minion = wd_path + "/bin/irma_config/FLU-minion-container.sh"
config_path_sc_spike = wd_path + "/bin/irma_config/s-gene-container.sh"
config_path_sc_wgs = wd_path + "/bin/irma_config/SC2-WGS-Nanopore.sh"

try:
    with open(fastq) as infi:
        contents = infi.readlines()
except:
    with gzip.open(fastq) as infi:
        contents = infi.readlines()

if exp_type == "Flu-ONT":
    irma_custom_0 = ""
    irma_custom_1 = f"--external-config {config_path_flu_minion}"
    subsample = "50000"
elif exp_type == "SC2-Spike-Only-ONT":
    irma_custom_0 = ""
    irma_custom_1 = f"--external-config {config_path_sc_spike}"
    subsample = "5000"
elif exp_type == "SC2-Whole-Genome-ONT":
    irma_custom_0 = ""
    irma_custom_1 = f"--external-config {config_path_sc_wgs}"
    subsample = "50000"

if exp_type == "Flu-ONT":
    IRMA_module = "FLU-minion"
elif exp_type == "SC2-Spike-Only-ONT":
    IRMA_module = "CoV-s-gene"
elif exp_type == "SC2-Whole-Genome-ONT":
    IRMA_module = "CoV"

filename = f"{sample}_chemistry.csv"
headers = "sample_ID,irma_custom_0,irma_custom_1,subsample,irma_module\n"
with open(filename, "w") as file:
    file.write(
        headers
        + f"{sample},{irma_custom_0},{irma_custom_1},{subsample},{IRMA_module}\n"
    )
