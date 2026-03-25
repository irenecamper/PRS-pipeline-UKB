# UKB PRS Pipeline on DNAnexus

Simple 3-step PRS pipeline using UK Biobank imputed data.

## Setup
```bash
git clone <your-repo-url>
cd ukb-prs-pipeline
conda env create -f environment.yml
conda activate ukb-prs
dx login
```

## Run
```bash
bash scripts/01_extract_cohort.sh
bash scripts/02_calculate_score.sh
bash scripts/03_sum_scores_R.sh
```