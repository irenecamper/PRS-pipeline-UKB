#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# sum per-chromosome PRS scores into a single all-chromosome score on DNAnexus
#
# this script:
#   1. reads chromosome-specific PRS output files (PRS_pred_*.sscore)
#   2. sums the SCORE1_SUM column across chromosomes for each IID
#   3. writes a combined output file
#
# required inputs:
#   - PRS_pred_*.sscore files in the input predictions folder
#
# output:
#   - PRS_pred_allchr.sscore
###############################################################################

############################
# user-editable parameters #
############################

INPUT_FOLDER="project-J6Qfq08J1xYbPpBBK9234GyX:/inputs/predictions"
OUTPUT_FOLDER="project-J6Qfq08J1xYbPpBBK9234GyX:/inputs/"

# DNAnexus instance type
INSTANCE_TYPE="mem1_ssd1_v2_x16"

# Output filename
OUTPUT_FILE="PRS_pred_allchr.sscore"

########################
# derived mount path   #
########################

# converts:
#   project-xxxx:/inputs/predictions
# to:
#   /mnt/project/inputs/predictions
INPUT_MOUNT="/mnt/project${INPUT_FOLDER#*:}"

########################
# R summing command    #
########################

run_sum_cmd="Rscript -e '
if (!require(\"dplyr\", quietly = TRUE)) {
  install.packages(\"dplyr\", repos = \"https://cloud.r-project.org\")
}
if (!require(\"readr\", quietly = TRUE)) {
  install.packages(\"readr\", repos = \"https://cloud.r-project.org\")
}

library(\"dplyr\")
library(\"readr\")

file_dir <- \"${INPUT_MOUNT}\"
file_list <- list.files(
  file_dir,
  pattern = glob2rx(\"PRS_pred_*.sscore\"),
  full.names = TRUE
)

if (length(file_list) == 0) {
  stop(paste(\"No PRS_pred_*.sscore files found in\", file_dir))
}

summed_data <- data.frame(IID = integer(), SCORE1_SUM = numeric())

for (file in file_list) {
  data <- read_delim(file, delim = \"\t\", show_col_types = FALSE)

  summed_file <- data %>%
    group_by(IID) %>%
    summarise(SCORE1_SUM = sum(SCORE1_SUM, na.rm = TRUE), .groups = \"drop\")

  summed_data <- summed_data %>%
    full_join(summed_file, by = \"IID\") %>%
    mutate(SCORE1_SUM = coalesce(SCORE1_SUM.x, 0) + coalesce(SCORE1_SUM.y, 0)) %>%
    select(IID, SCORE1_SUM)
}

output_file <- \"/home/dnanexus/out/out/${OUTPUT_FILE}\"

write.table(
  summed_data,
  file = output_file,
  row.names = FALSE,
  col.names = TRUE,
  quote = FALSE,
  sep = \"\t\"
)
'"

########################
# run on DNAnexus      #
########################

dx run swiss-army-knife \
  -icmd="${run_sum_cmd}" \
  --instance-type "${INSTANCE_TYPE}" \
  --name "03_sum_scores" \
  --destination="${OUTPUT_FOLDER}/" \
  --brief \
  --yes