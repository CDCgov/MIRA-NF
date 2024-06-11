import argparse
import gzip

parser = argparse.ArgumentParser(
    description="Find chemistry information from fastq files."
)
parser.add_argument("-s", "--sample", required=True, help="Sample name")
parser.add_argument("-q", "--fastq", required=True, help="R1.fastq file path")
parser.add_argument("-r", "--runid", required=True, help="Run ID")
parser.add_argument("-e", "--exp_type", required=True, help="Exp type")

args = parser.parse_args()

sample = args.sample
fastq = args.fastq
runid = args.runid
runid = args.runid
exp_type = args.exp_type

try:
    with open(fastq) as infi:
        contents = infi.readlines()
except:
    with gzip.open(fastq) as infi:
        contents = infi.readlines()

if len(contents[1]) > 145:
    irma_custom = ["", ""]
    subsample = "50000"
# elif len(contents[1]) > 70:
#    config_path = "/home/try8/spyne_nextflow/workflow/irma_contif/FLU-2x75.sh"
#    irma_custom = [f"mkdir -p /home/try8/results/IRMA && cp {config_path} /home/try8/results/IRMA/ &&", f"--external-config /data/{runid}/IRMA/FLU-2x75.sh"]
#    subsample = "200000"

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
        + f"{sample},{irma_custom[0]},{irma_custom[1]},{subsample},{IRMA_module}\n"
    )
