#!/bin/bash

source config.sh

# Extract regions, create LD matrices

wget https://raw.githubusercontent.com/MRCIEU/genotype-phenotype-map/refs/heads/main/pipeline_steps/data/ld_regions_hg38.tsv?token=GHSAT0AAAAAAB3FN3SCPKTY5OSPPLRYOHQWZXZ5FKQ -O ld_regions_hg38.tsv

dx rm ${project}:${datadir}/ld_regions_hg38.tsv
dx upload ld_regions_hg38.tsv --destination="${project}:${datadir}/" -p
dx rm ${project}:${datadir}/run.sh
dx upload run.sh --destination="${project}:${datadir}/" -p

for chr in {1..22}
do
    dx run swiss-army-knife \
        -iin="${project}:${datadir}/run.sh" \
        -icmd="bash run.sh ${chr}" \
        --destination="${project}:${datadir}/" \
        --brief \
        --yes \
        --instance-type="mem1_ssd2_v2_x8" \
        --name="ld_matrix_${chr}"
done
