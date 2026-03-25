# UKB PRS Pipeline on DNAnexus

Simple 3-step PRS pipeline using UK Biobank imputed data.

## Setup
```bash
git clone https://github.com/irenecamper/PRS-pipeline-UKB.git
python3 -m venv .venv
source .venv/bin/activate
pip3 install dxpy
dx login
```

## Run
```bash
sh scripts/01_extract_cohort.sh
sh scripts/02_calculate_score.sh
sh scripts/03_sum_scores_R.sh
```