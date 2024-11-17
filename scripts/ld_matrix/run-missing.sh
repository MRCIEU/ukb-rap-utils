#!/bin/bash

set -e

zf="plink2_linux_avx2_20241114.zip"
wget https://s3.amazonaws.com/plink2-assets/alpha6/$zf && unzip $zf && rm $zf

ancs=$(sed 1d /mnt/project/data/ldmatrix2/missing_blocks.txt | awk '{print $4}' | sort | uniq | tr '\n' ' ')
ancs=(`echo $ancs`)

for chr in {1..22}
    for anc in ${ancs[@]}
    do
        head -n 50000 /mnt/project/data/ancestry/king/ids_${anc}.fam > ids_${anc}_keep.fam

        awk -v chr="$chr" -v anc="$anc" '{if($1 == chr && $4 == anc) {print $0}}' /mnt/project/data/ldmatrix2/missing_blocks.txt > ld_regions.tsv
        nrow=$(wc -l ld_regions.tsv | awk '{print $1}')
        echo $nrow

        for row in $(seq 1 $nrow)
        do
            chr=$(awk -v row="$row" 'NR==row {print $1}' ld_regions.tsv)
            start=$(awk -v row="$row" 'NR==row {print $2}' ld_regions.tsv)
            end=$(awk -v row="$row" 'NR==row {print $3}' ld_regions.tsv)
            echo $chr $start $end

            mkdir -p ${anc}/${chr}

            ./plink2 \
                --bfile /mnt/project/data/plink/ukb21007_c${chr}_b0_v1 \
                --chr ${chr} \
                --from-bp ${start} \
                --to-bp ${end} \
                --maf 0.005 \
                --keep ids_${anc}_keep.fam \
                --keep-allele-order \
                --make-bed \
                --out ${anc}/${chr}/${start}-${end}

            ./plink2 \
                --bfile ${anc}/${chr}/${start}-${end} \
                --r-unphased square ref-based \
                --keep-allele-order \
                --out ${anc}/${chr}/${start}-${end}

            ./plink2 \
                --bfile ${anc}/${chr}/${start}-${end} \
                --freq \
                --keep-allele-order \
                --out ${anc}/${chr}/${start}-${end}
        done
    done
done

rm ld_regions.tsv
rm ids_*_keep.fam
rm plink2