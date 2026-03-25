#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# prepare imputed UK Biobank genotype data for PRS using PLINK2 on DNAnexus
#
# what this script does:
#   1. loops through chromosomes 1–22
#   2. reads UKB imputed BGEN + SAMPLE files
#   3. keeps only selected SNPs (from an rsID list)
#   4. keeps only selected individuals (from FID/IID keep file)
#   5. converts to PGEN
#   6. removes duplicate variants
#   7. converts to BED/BIM/FAM
#   8. writes outputs back to DNAnexus
#
# required input files:
#   - sample_ids.txt : PLINK keep file with FID and IID columns
#   - rsids.txt      : one rsID per line
#
# outputs:
#   - for chr1–22: ${DATA_FIELD}_c<chr>_qced.{bed,bim,fam}
#   - for chrX:    ${DATA_FIELD}_cX_qced.{bed,bim,fam}
#
# run by sh ./01_extract_cohort.sh  
###############################################################################

############################
# user-editable parameters #
############################

# UKB data field
# examples:
#   ukb22828 = UKB imputation from genotype
#   ukb21007 = TOPMed imputation from genotype
DATA_FIELD="ukb22828"

# DNAnexus folder containing the chromosome-level BGEN and SAMPLE files
IMP_FILE_DIR="/Bulk/Imputation/UKB imputation from genotype"
# alternative:
# IMP_FILE_DIR="/Bulk/Imputation/Imputation from genotype (TOPmed)"

# DNAnexus project folder where my input files are stored
INPUT_FOLDER="project-J6Qfq08J1xYbPpBBK9234GyX:/inputs/"

# DNAnexus destination folder for outputs
OUTPUT_FOLDER="project-J6Qfq08J1xYbPpBBK9234GyX:/prs_qc/"

# input files located in INPUT_FOLDER
# optional run: dx upload inputs/sample_ids.txt --destination project-J6Qfq08J1xYbPpBBK9234GyX:/inputs
# optional run: dx upload inputs/rsids.txt --destination project-J6Qfq08J1xYbPpBBK9234GyX:/inputs
KEEP_FILE="sample_ids.txt"
SNPS_FILE="rsids.txt"

# chromosomes to process
CHR_START=1
CHR_END=22

# DNAnexus instance type
INSTANCE_TYPE="mem2_ssd2_v2_x16"

########################
# basic sanity checks  #
########################

if ! command -v dx >/dev/null 2>&1; then
  echo "ERROR: dx command not found. Load or install the DNAnexus CLI first."
  exit 1
fi

########################
# main chromosome loop #
########################

for CHR in $(seq "${CHR_START}" "${CHR_END}"); do
  echo "============================================================"
  echo "processing chromosome ${CHR}"
  echo "============================================================"

  BGEN_FILE="${DATA_FIELD}_c${CHR}_b0_v3.bgen"
  SAMPLE_FILE="${DATA_FIELD}_c${CHR}_b0_v3.sample"
  TEMP_PREFIX="ukbi_ch${CHR}_v3"
  FINAL_PREFIX="${DATA_FIELD}_c${CHR}_qced"

  # command that will run inside swiss-army-knife
  RUN_PLINK_CMD=$(cat <<EOF
plink2 \
  --bgen ${BGEN_FILE} ref-first \
  --sample ${SAMPLE_FILE} \
  --extract ${SNPS_FILE} \
  --keep ${KEEP_FILE} \
  --make-pgen \
  --out ${TEMP_PREFIX} && \
plink2 \
  --pfile ${TEMP_PREFIX} \
  --no-pheno \
  --rm-dup force-first \
  --make-bed \
  --out ${FINAL_PREFIX} && \
rm -f ${TEMP_PREFIX}.pgen ${TEMP_PREFIX}.pvar ${TEMP_PREFIX}.psam ${TEMP_PREFIX}.log
EOF
)

  dx run swiss-army-knife \
    -iin="${IMP_FILE_DIR}/${BGEN_FILE}" \
    -iin="${IMP_FILE_DIR}/${SAMPLE_FILE}" \
    -iin="${INPUT_FOLDER}/${KEEP_FILE}" \
    -iin="${INPUT_FOLDER}/${SNPS_FILE}" \
    -icmd="${RUN_PLINK_CMD}" \
    --instance-type "${INSTANCE_TYPE}" \
    --name "01_PRS_qc_ch${CHR}" \
    --destination="${OUTPUT_FOLDER}/" \
    --brief \
    --yes
done

# ########################
# # process chromosome X
# ########################

# echo "============================================================"
# echo "processing chromosome X"
# echo "============================================================"

# BGEN_FILE_X="${DATA_FIELD}_cX_b0_v3.bgen"
# SAMPLE_FILE_X="${DATA_FIELD}_cX_b0_v3.sample"
# TEMP_PREFIX_X="ukbi_chX_v3"
# FINAL_PREFIX_X="${DATA_FIELD}_cX_qced"

# RUN_PLINK_CMD_X=$(cat <<EOF
# plink2 \
#   --bgen ${BGEN_FILE_X} ref-first \
#   --sample ${SAMPLE_FILE_X} \
#   --set-all-var-ids @:#:'\$r':'\$a' \
#   --new-id-max-allele-len 99 truncate \
#   --make-pgen \
#   --out ${TEMP_PREFIX_X} && \
# plink2 \
#   --pfile ${TEMP_PREFIX_X} \
#   --no-pheno \
#   --keep ${KEEP_FILE} \
#   --maf 0.01 \
#   --mac 100 \
#   --geno 0.1 \
#   --mind 0.1 \
#   --hwe 1e-15 \
#   --rm-dup force-first \
#   --make-bed \
#   --out ${FINAL_PREFIX_X} && \
# rm -f ${TEMP_PREFIX_X}.pgen ${TEMP_PREFIX_X}.pvar ${TEMP_PREFIX_X}.psam ${TEMP_PREFIX_X}.log
# EOF
# )

# dx run swiss-army-knife \
#   -iin="${IMP_FILE_DIR}/${BGEN_FILE_X}" \
#   -iin="${IMP_FILE_DIR}/${SAMPLE_FILE_X}" \
#   -iin="${INPUT_FOLDER}/${KEEP_FILE}" \
#   -icmd="${RUN_PLINK_CMD_X}" \
#   --instance-type "${INSTANCE_TYPE}" \
#   --name "01_PRS_qc_chX" \
#   --destination="${OUTPUT_FOLDER}/" \
#   --brief \
#   --yes
