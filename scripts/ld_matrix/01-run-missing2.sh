#!/bin/bash

source config.sh

# Extract regions, create LD matrices

dx rm ${project}:${datadir}/ld_blocks.tsv
dx upload ld_blocks.tsv --destination="${project}:${datadir}/" -p

dx rm ${project}:${datadir}/missing_blocks2.txt
dx upload missing_blocks2.txt --destination="${project}:${datadir}/" -p

dx rm ${project}:${datadir}/run-missing2.sh
dx upload run-missing2.sh --destination="${project}:${datadir}/" -p

chr=22
for chr in {1..21}
do
    dx run swiss-army-knife \
        -iin="${project}:${datadir}/run-missing2.sh" \
        -icmd="bash run-missing2.sh $chr" \
        --destination="${project}:${datadir}/" \
        --brief \
        --yes \
        --instance-type="mem1_ssd2_v2_x8" \
        --name="ld_matrix_missing2"
done
