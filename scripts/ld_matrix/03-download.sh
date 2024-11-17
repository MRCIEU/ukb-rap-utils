#!/bin/bash

source config.sh

dx download "${project}:${datadir}/missing_blocks.txt"

grep EUR missing_blocks.txt > EUR_missing_blocks.txt
nmiss=$(cat EUR_missing_blocks.txt | wc -l)
echo $nmiss
mkdir -p missing

for i in $(seq 1 $nmiss); do
    awk "NR==$i"  EUR_missing_blocks.txt
    chr=$(awk -v i=$i 'NR==i { print $1 }' EUR_missing_blocks.txt)
    mkdir -p missing/${chr}
    start=$(awk -v i=$i 'NR==i { print $2 }' EUR_missing_blocks.txt)
    stop=$(awk -v i=$i 'NR==i { print $3 }' EUR_missing_blocks.txt)
    rn="${project}:${datadir}/EUR/${chr}/${start}-${stop}"
    echo $rn
    dx download "${rn}.afreq" -o missing/${chr}/
    dx download "${rn}.bed" -o missing/${chr}/
    dx download "${rn}.bim" -o missing/${chr}/
    dx download "${rn}.fam" -o missing/${chr}/
    dx download "${rn}.unphased.vcor1" -o missing/${chr}/
    dx download "${rn}.unphased.vcor1.vars" -o missing/${chr}/
done
