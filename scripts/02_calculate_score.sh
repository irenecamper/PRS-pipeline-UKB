#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# calculate per-chromosome PRS scores with PLINK2 on DNAnexus
#
# this script:
#   1. loops through selected chromosomes
#   2. loads chromosome-specific PLINK files (.bed/.bim/.fam)
#   3. applies a PRS score file using PLINK2 --score
#   4. outputs PRS scores per chromosome
#
# required inputs:
#   - ${DATA_FIELD}_c<chr>_qced.{bed,bim,fam}
#   - score_file.txt
#
# output:
#   - PRS_pred_<chr>.sscore
###############################################################################

############################
# user-editable parameters #
############################

DATA_FIELD="ukb22828"

# optional run: dx upload inputs/score_file.txt --destination project-J6Qfq08J1xYbPpBBK9234GyX:/inputs/
INPUT_FOLDER="project-J6Qfq08J1xYbPpBBK9234GyX:/inputs"
INPUT_QC_FOLDER="project-J6Qfq08J1xYbPpBBK9234GyX:/prs_qc"
OUTPUT_FOLDER="${INPUT_FOLDER}/predictions/"

SCORE_FILE="score_file.txt"

# Chromosomes to process
CHRS=(2 3 5 11 15 16)

# DNAnexus instance type
INSTANCE_TYPE="mem2_ssd2_v2_x16"

########################
# basic sanity checks  #
########################

if ! command -v dx >/dev/null 2>&1; then
  echo "ERROR: dx command not found."
  exit 1
fi

# Create output folder if needed
dx mkdir -p "${OUTPUT_FOLDER}" >/dev/null 2>&1 || true

########################
# scoring loop         #
########################

for CHR in "${CHRS[@]}"; do
  echo "============================================================"
  echo "scoring chromosome ${CHR}"
  echo "============================================================"

  BFILE_PREFIX="${DATA_FIELD}_c${CHR}_qced"
  OUT_PREFIX="PRS_pred_${CHR}"

  RUN_PLINK_CMD=$(cat <<EOF
plink2 \
  --bfile ${BFILE_PREFIX} \
  --score ${SCORE_FILE} 1 2 3 header list-variants ignore-dup-ids cols=+scoresums \
  --out ${OUT_PREFIX}
EOF
)

  dx run swiss-army-knife \
    -iin="${INPUT_QC_FOLDER}/${BFILE_PREFIX}.bed" \
    -iin="${INPUT_QC_FOLDER}/${BFILE_PREFIX}.bim" \
    -iin="${INPUT_QC_FOLDER}/${BFILE_PREFIX}.fam" \
    -iin="${INPUT_FOLDER}/${SCORE_FILE}" \
    -icmd="${RUN_PLINK_CMD}" \
    --instance-type "${INSTANCE_TYPE}" \
    --name "01_PRS_pred_ch${CHR}" \
    --destination="${OUTPUT_FOLDER}/" \
    --brief \
    --yes
done

########################
# optional: chromosome X
########################

# uncomment if needed
#
# echo "============================================================"
# echo "scoring chromosome X"
# echo "============================================================"
#
# BFILE_PREFIX_X="${DATA_FIELD}_cX_qced"
# OUT_PREFIX_X="PRS_pred_X"
#
# RUN_PLINK_CMD_X=$(cat <<EOF
# plink2 \
#   --bfile ${BFILE_PREFIX_X} \
#   --score ${SCORE_FILE} 1 2 3 header list-variants ignore-dup-ids cols=+scoresums \
#   --out ${OUT_PREFIX_X}
# EOF
# )
#
# dx run swiss-army-knife \
#   -iin="${INPUT_QC_FOLDER}/${BFILE_PREFIX_X}.bed" \
#   -iin="${INPUT_QC_FOLDER}/${BFILE_PREFIX_X}.bim" \
#   -iin="${INPUT_QC_FOLDER}/${BFILE_PREFIX_X}.fam" \
#   -iin="${INPUT_FOLDER}/${SCORE_FILE}" \
#   -icmd="${RUN_PLINK_CMD_X}" \
#   --instance-type "${INSTANCE_TYPE}" \
#   --name "01_PRS_pred_chX" \
#   --destination="${OUTPUT_FOLDER}/" \
#   --brief \
#   --yes