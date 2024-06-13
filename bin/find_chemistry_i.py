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
config_path_sc_wgs_i = wd_path + "/bin/irma_config/s-gene-container.sh"

try:
    with open(fastq) as infi:
        contents = infi.readlines()
except:
    with gzip.open(fastq) as infi:
        contents = infi.readlines()

if len(contents[1]) > 145 and exp_type == "Flu_Illumina":
    irma_custom_0 = ""
    irma_custom_1 = ""
    subsample = "100000"
elif len(contents[1]) > 80 and exp_type == "SC2-Whole-Genome-Illumina":
    irma_custom_0 = ""
    irma_custom_1 = ""
    subsample = "100000"
elif len(contents[1]) < 80 and exp_type == "SC2-Whole-Genome-Illumina":
    irma_custom_0 = ""
    irma_custom_1 = f"--external-config {config_path_sc_wgs_i}"
    subsample = "200000"

if exp_type == "Flu_Illumina":
    IRMA_module = "FLU"
elif exp_type == "SC2-Whole-Genome-Illumina":
    IRMA_module = "CoV"

filename = f"{sample}_chemistry.csv"
headers = "sample_ID,irma_custom_0,irma_custom_1,subsample,irma_module\n"
with open(filename, "w") as file:
    file.write(
        headers
        + f"{sample},{irma_custom_0},{irma_custom_1},{subsample},{IRMA_module}\n"
    )
