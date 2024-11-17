#!/bin/bash

source config.sh

# Extract regions, create LD matrices

wget https://raw.githubusercontent.com/MRCIEU/genotype-phenotype-map/refs/heads/main/pipeline_steps/data/ld_blocks.tsv?token=GHSAT0AAAAAAB3FN3SD4BP2NIN27MXCNAJMZZZ5TUA -O ld_blocks.tsv

diff <(sort ld_blocks.tsv) <(sort ld_regions_hg38.tsv) | grep "^<" | sed 's/^< //' | sort -r > missing_blocks.txt


dx rm ${project}:${datadir}/ld_blocks.tsv
dx upload ld_blocks.tsv --destination="${project}:${datadir}/" -p

dx rm ${project}:${datadir}/missing_blocks.txt
dx upload missing_blocks.txt --destination="${project}:${datadir}/" -p

dx rm ${project}:${datadir}/run-missing.sh
dx upload run-missing.sh --destination="${project}:${datadir}/" -p
dx run swiss-army-knife \
    -iin="${project}:${datadir}/run-missing.sh" \
    -icmd="bash run-missing.sh" \
    --destination="${project}:${datadir}/" \
    --brief \
    --yes \
    --instance-type="mem1_ssd2_v2_x8" \
    --name="ld_matrix_missing"

