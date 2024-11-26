#!/usr/bin/env python

# Referencing https://plotly.com/python/v3/html-reports/#step-2-generate-html-reportas-a-string-and-write-to-file

import os
import plotly.graph_objects as go
import plotly.io as pio
from plotly.subplots import make_subplots
import pandas as pd
import base64
import glob
from os.path import dirname, realpath
from sys import argv
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-d", "--data_path", help="the file path to the data")
parser.add_argument("-r", "--run_path", help="the file path to the data")
parser.add_argument(
    "-l", "--logo_path", help="the file path to the assests folder containing the logos"
)

inputarguments = parser.parse_args()

if inputarguments.data_path:
    data_root = inputarguments.data_path
else:
    data_root = Path.cwd()

if inputarguments.run_path:
    run_root = inputarguments.run_path
else:
    run_root = data_root

if inputarguments.logo_path:
    logo_path = inputarguments.logo_path
else:
    logo_path = ""

run = os.path.basename(run_root)

# image locations
mira_logo = f"{logo_path}/assets/mira-logo-midjourney_20230526_rmbkgnd.png"
favicon = f"{logo_path}/assets/favicon.ico"
excel_logo = f"{logo_path}/assets/Microsoft_Excel-Logo.png"


# base64 encode images
def base64_fun(_img):
    _binary = open(f"{_img}", "rb").read()
    _base64 = base64.b64encode(_binary).decode("utf-8")
    return _base64


base64_logo = base64_fun(mira_logo)
base64_favicon = base64_fun(favicon)
base64_excellogo = base64_fun(excel_logo)

# read MIRA barcode distribution pie
try:
    bdp_html = pio.read_json(f"{data_root}/barcode_distribution.json").to_html(
        config={
            "toImageButtonOptions": {
                "format": "svg",
                "filename": f"MIRA_barcode_distribution_pie.svg",
            }
        },
    )
except:
    bdp_html = """<p>No barcode results</p>"""

# read MIRA pass fail heatmap json and make html string
try:
    pfhm_html = pio.read_json(f"{data_root}/pass_fail_heatmap.json").to_html(
        config={
            "toImageButtonOptions": {
                "format": "svg",
                "filename": f"MIRA_passfail_heatmap.svg",
            }
        },
    )
except:
    pfhm_html = """<p>No automatic qc results</p>"""

# read MIRA coverage heatmap and make html string
try:
    chm_html = pio.read_json(f"{data_root}/heatmap.json").to_html(
        config={
            "toImageButtonOptions": {
                "format": "svg",
                "filename": f"MIRA_coverage_summary_heatmap.svg",
            }
        },
    )
except:
    chm_html = """<p>No coverage results</p>"""

# read MIRA irma summary table json and make html string
try:
    irma_sum_pd = pd.read_json(f"{data_root}/irma_summary.json", orient="split")
    irma_sum_pd.to_excel(f"MIRA_{run}_summary.xlsx", engine="openpyxl", index=False)
    irma_sum_html = go.Figure(
        data=[
            go.Table(
                header=dict(
                    values=list(irma_sum_pd.columns),
                    fill_color="paleturquoise",
                    align="left",
                ),
                cells=dict(
                    values=[
                        irma_sum_pd["Sample"],
                        irma_sum_pd["Total Reads"],
                        irma_sum_pd["Pass QC"],
                        irma_sum_pd["Reads Mapped"],
                        irma_sum_pd["Reference"],
                        irma_sum_pd["% Reference Covered"],
                        irma_sum_pd["Median Coverage"],
                        irma_sum_pd["Count of Minor SNVs >= 0.05"],
                        irma_sum_pd["Count of Minor Indels >= 0.05"],
                        irma_sum_pd["Pass/Fail Reason"],
                        irma_sum_pd["MIRA module"],
                    ],
                    fill_color="lavender",
                    align="left",
                ),
            )
        ]
    ).to_html()
except:
    irma_sum_html = """<p>No MIRA summary results</p>"""

# save html images of coverage plots/sample and make links as html for summary
coverage_links_html = """<h2>Individual Sample Coverage Figures</h2><p2>"""
try:
    for cf in glob.glob(f"{data_root}/coveragefig*linear.json"):
        coveragefig = pio.read_json(cf)
        sample = (
            cf.split("/")[-1].replace("coveragefig_", "").replace("_linear.json", "")
        )
        print(f"sample = {sample}")
        sankeyfig = pio.read_json(f"{data_root}/readsfig_{sample}.json")
        # sankeyfig.write_html(f"MIRA_{sample}_sankey.html")
        with open(f"MIRA_{sample}_coverage.html", "a") as out:
            out.write(
                sankeyfig.to_html(
                    full_html=False,
                    config={
                        "toImageButtonOptions": {
                            "format": "svg",
                            "filename": f"MIRA_{sample}_sankey.svg",
                        }
                    },
                )
            )
            out.write(
                coveragefig.to_html(
                    full_html=False,
                    config={
                        "toImageButtonOptions": {
                            "format": "svg",
                            "filename": f"MIRA_{sample}_coverage.svg",
                        }
                    },
                )
            )
        # fmt: off
        coverage_links_html += '''<a href="./MIRA_'''+f'{sample}'+'''_coverage.html" target="_blank" >'''+f'{sample}'+'''</a><br>'''
        # fmt: on
    coverage_links_html += "</p2>"
except:
    coverage_links_html += """<p>No coverage results</p>"""

# read MIRA dais var table json and make html string
try:
    dais_var_pd = pd.read_json(f"{data_root}/dais_vars.json", orient="split")
    dais_var_pd.to_excel(f"MIRA_{run}_aavars.xlsx", engine="openpyxl", index=False)
    dais_var_html = go.Figure(
        data=[
            go.Table(
                header=dict(
                    values=list(dais_var_pd.columns),
                    fill_color="paleturquoise",
                    align="left",
                ),
                cells=dict(
                    values=[
                        dais_var_pd["Sample"],
                        dais_var_pd["Reference"],
                        dais_var_pd["Protein"],
                        dais_var_pd["AA Variant Count"],
                        dais_var_pd["AA Variants"],
                    ],
                    fill_color="lavender",
                    align="left",
                ),
            )
        ]
    ).to_html()
except:
    dais_var_html = """<p>No MIRA amino acid variant results</p>"""

# link to minor variants table
try:
    mvdf = pd.read_json(f"{data_root}/alleles.json", orient="split")
    mvdf.to_excel(f"MIRA_{run}_minorvariants.xlsx", engine="openpyxl", index=False)
    # fmt: off
    minorvars_links_html = '''<p2><a href="./MIRA_'''+f'{run}'+'''_minorvariants.xlsx" download>Download minor variants table</a></p2><br>'''
    # fmt: on
except:
    minorvars_links_html = """<p2>No minor variants table</p2>"""

# link to indels table
try:
    indels_df = pd.read_json(f"{data_root}/indels.json", orient="split")
    indels_df.to_excel(f"MIRA_{run}_minorindels.xlsx", engine="openpyxl", index=False)
    # fmt: off
    indels_links_html = '''<p2><a href="./MIRA_'''+f'{run}'+'''_minorindels.xlsx" download>Download minor indels table</a></p2><br>'''
    # fmt: on
except:
    indels_links_html = """<p2>No indels table</p2>"""

# link to fastas
fasta_links_html = (
    """<h2>Fasta downloads</h2><p3>(Right-click->"Save link as...")</p3><br><p>"""
)
try:
    for f in glob.glob(f"{data_root}/*fasta"):
        kind = f.split("/")[-1]
        with open(f) as _file:
            content = "".join(_file.readlines())
            with open(f"MIRA_{run}_{kind}", "w") as out:
                out.write(content)
        # fmt: off
        fasta_links_html += '''<a href="'''+f"./MIRA_{run}_{kind}"+'''" download>'''+f"{kind}"+'''</a><br><br>'''
        # fmt: on
    fasta_links_html += """</p2>"""
except:
    fasta_links_html += """No fasta files</p2>"""

# Make sure Black formatter does not mess up html block.
# fmt: off
html_string ='''
<html>
    <head>
        <style>
        h1 {text-align: center;
            font-family: Helvetica;}
        h2 {text-align: center;
            font-family: Helvetica;
            margin-bottom: 2px;}
        head {text-align: center; 
            font-family: Helvetica;
            margin-top: 20px; 
            margin-left: 100px;
            margin-right: 100px;}
        body {text-align: center; 
            font-family: Helvetica;
            margin-bottom: 20px;
            margin-left: 100px;
            margin-right: 100px;}
        p1 {text-align: left; 
            font-family: Helvetica;
            margin-top: 20px; 
            margin-bottom: 20px;
            margin-left: 300px;
            margin-right: 300px;}
        p2 {text-align: center;
            font-size: 25px;
            font-family: Helvetica;
            margin-bottom: 20px;
        p2 {text-align: center;
            font-family: Helvetica;
            margin-bottom: 20px;
        </style>
        <title>MIRA Summary</title>
        <link rel="icon" type="image/x-icon" href="data:image/png;base64,'''+f'{base64_favicon}'+ '''">
        <img src="data:image/png;base64,'''+f'{base64_logo}'+ '''">
        <h1>MIRA Summary Report</h1>
        <h2>'''+f'{run}'+'''</h2>
    </head>
    <hr>
    <hr>
    <body>
        <h2>Barcode Assignment</h2>
        '''+f'{bdp_html}'+'''
            <p1>The ideal result would be a similar number of reads assigned to each test and positive 
            control. However, it is ok to not have similar read numbers per sample. Samples with a low 
            proportion of reads may indicate higher Ct of starting material or less performant PCR 
            during library preparation. What is most important for sequencing assembly is raw count of 
            reads and their quality.</p1>            
        <hr>
        <h2>Automatic Quality Control Decisions</h2>
        '''+f'{pfhm_html}'+ '''
            <p1>MIRA requires a minimum median coverage of 50x, a minimum coverage of the reference 
            length of 90%, and less than 10 minor variants >=5%. These are marked in yellow to orange 
            according to the number of these failure types. Samples that failed to generate any assembly 
            are marked in red. In addition, premature stop codons are flagged in yellow. CDC does not 
            submit sequences with premature stop codons, particularly in HA, NA or SARS-CoV-2 Spike. 
            Outside of those genes, premature stop codons near the end of the gene may be ok for 
            submission. Hover your mouse over the figure to see individual results.</p1>
        <hr>
        <h2>Median Coverage</h2>
        '''+f'{chm_html}'+ '''
            <p1>The heatmap summarizes the mean coverage per sample per reference.</p1>
        <hr>
        <h2>MIRA Summary Table</h2>
        <a href="./MIRA_'''+f'{run}_summary.xlsx'+'''" download>
            <img src="data:image/png;base64,'''+f'{base64_excellogo}'+ '''" alt="Download excel" width="60" height="40">
        </a>
        '''+ f'{irma_sum_html}'+'''
        <hr>
        '''+f'{coverage_links_html}'+'''
        <hr>
        <h2>AA Variants Table</h2>
        <a href="./MIRA_'''+f'{run}_aavars.xlsx'+'''" download>
            <img src="data:image/png;base64,'''+f'{base64_excellogo}'+ '''" alt="Download excel" width="60" height="40">
        </a>
        '''+ f'{dais_var_html}'+'''
        <hr>
        <h2>Minor Table Download</h2>
        '''+f'{minorvars_links_html} {indels_links_html}'+'''
        <hr>
        '''+f'{fasta_links_html}'+'''
    </body>
</html>'''
# fmt: on


# html_string = html_string.replace(
#    "Download plot as a png", "Download plot as a svg"
# ).replace('format:e.format||"png"', 'format:e.format||"svg"')
#

with open(f"MIRA-summary-{run}.html", "w") as out:
    out.write(f"{html_string}")
