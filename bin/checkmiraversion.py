#!/usr/bin/env python

import argparse
import pandas as pd
import re

parser = argparse.ArgumentParser(
    description="Check the version of MIRA-NF and determine if their is a newer version"
)
parser.add_argument("-g", "--git_version", required=True, help="github url to description file on MIRA-NF github")
parser.add_argument("-l", "--local_version_path", required=True, help="path to local description file")

args = parser.parse_args()

git_version = args.git_version
local_version_path = args.local_version_path


with open(local_version_path + "/DESCRIPTION", "r") as d:
    current = "".join(d.readlines())
with open(git_version, "r") as d:
    available = "".join(d.readlines())
    current = re.findall(r"Version.+(?=\n)", current)[0]
    available = re.findall(r"Version.+(?=\n)", available)[0]
if current >= available:
    print(f"MIRA-NF version up to date!")
else:
    print(f"MIRA-NF " + available + " is now available!")
            