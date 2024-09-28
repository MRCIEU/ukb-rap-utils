#!/bin/bash

# get paths etc
source config.sh

# get a list of markers in linkage equilibtrium

cmd="
wget http://fileserve.mrcieu.ac.uk/ld/1kg.v3.tgz
tar xzvf 1kg.v3.tgz
rm 1kg.v3.tgz
"

echo $cmd

dx run swiss-army-knife \
    -icmd="${cmd}" \
    --destination="${project}:${datadir}/1kg_ref" \
    --brief \
    --yes


dx upload exclusion_regions_hg19.txt --destination="${project}:${datadir}/misc/" -p

for anc in EUR AFR AMR EAS SAS;
do
    echo $anc
    cmd="
    mkdir -p $anc
    plink --bfile $anc --indep-pairwise 1000 50 0.05 --exclude range exclusion_regions_hg19.txt --out ${anc}/1kg_$anc
    "
    echo $cmd
    dx run swiss-army-knife \
        -iin="${project}:${datadir}/1kg_ref/${anc}.bed" \
        -iin="${project}:${datadir}/1kg_ref/${anc}.bim" \
        -iin="${project}:${datadir}/1kg_ref/${anc}.fam" \
        -iin="${project}:${datadir}/misc/exclusion_regions_hg19.txt" \
        -icmd="${cmd}" \
        --destination="${project}:${datadir}/1kg_ref" \
        --brief \
        --yes
done


# prune the UKB data and create a single fileset
cmd='
mkdir -p pruning
touch pruning/mergelist.txt
shuf -n 50000 "/mnt/project/Bulk/Genotype Results/Genotype calls/ukb22418_c1_b0_v2.fam" > keep.fam
for i in {1..22};
do
    plink2 --bfile "/mnt/project/Bulk/Genotype Results/Genotype calls/ukb22418_c${i}_b0_v2" --keep keep.fam --indep-pairwise 1000 50 0.05 --exclude range exclusion_regions_hg19.txt --out pruning/ukb22418_c${i}_b0_v2

    plink2 --bfile "/mnt/project/Bulk/Genotype Results/Genotype calls/ukb22418_c${i}_b0_v2" --extract pruning/ukb22418_c${i}_b0_v2.prune.in --make-bed --out pruning/ukb22418_c${i}_b0_v2_pruned
    
    echo "pruning/ukb22418_c${i}_b0_v2_pruned" >> pruning/mergelist.txt
done

plink2 --pmerge-list pruning/mergelist.txt bfile --make-bed --out pruning/ukb22418_all_b0_v2_pruned

mkdir -p ukb_pruned
mv pruning/ukb22418_all_b0_v2_pruned.bed pruning/ukb22418_all_b0_v2_pruned.bim pruning/ukb22418_all_b0_v2_pruned.fam ukb_pruned
rm -r pruning
'

echo $cmd
dx run swiss-army-knife \
    -iin="${project}:${datadir}/misc/exclusion_regions_hg19.txt" \
    -icmd="${cmd}" \
    --destination="${project}:${datadir}" \
    --brief \
    --instance-type "mem1_ssd1_v2_x16" \
    --yes

# use KING to project samples to ancestries
cmd="
# Download king
wget https://www.kingrelatedness.com/Linux-king.tar.gz
tar xzvf Linux-king.tar.gz
chmod 755 king
rm Linux-king.tar.gz

# Download reference datasets
wget https://www.kingrelatedness.com/ancestry/KGref.bed.xz
unxz KGref.bed.xz

wget https://www.kingrelatedness.com/ancestry/KGref.bim.xz
unxz KGref.bim.xz

wget https://www.kingrelatedness.com/ancestry/KGref.fam.xz
unxz KGref.fam.xz

# Install e1071 and data.table libraries
Rscript -e \"install.packages(c('e1071'))\"

plink2 --bfile /mnt/project/data/ancestry/ukb_pruned/ukb22418_all_b0_v2_pruned --maf 0.01 --mind 0.1 --geno 0.1 --hwe 0.000001 --out ukb_cleaned --make-bed
# Run KING
./king -b KGref.bed,ukb_cleaned.bed --pca --projection --pngplot --prefix ukb --cpus 16

# Remove unnecessary files
rm KGref.*
rm king
rm ukb_cleaned.*
"

echo $cmd
dx run swiss-army-knife \
    -icmd="${cmd}" \
    --destination="${project}:${datadir}/king/" \
    --brief \
    --yes \
    --instance-type "mem1_ssd1_v2_x16"

# Note that at this point the ancestry plot fails because of the svm not specifying classification
# https://stackoverflow.com/questions/43499772/svmneed-numeric-dependent-variable-for-regression
dx upload king_ancestry.r --destination="${project}:${datadir}/king/" -p

cmd="
Rscript -e \"install.packages(c('e1071','dplyr'))\"
Rscript king_ancestry.r
# Get ancestry lists
awk '{ if (\$9 == \"EUR\") print \$1 }' ukb_InferredAncestry.txt > ids_EUR.txt
awk '{ if (\$9 == \"AFR\") print \$1 }' ukb_InferredAncestry.txt > ids_AFR.txt
awk '{ if (\$9 == \"SAS\") print \$1 }' ukb_InferredAncestry.txt > ids_SAS.txt
awk '{ if (\$9 == \"EAS\") print \$1 }' ukb_InferredAncestry.txt > ids_EAS.txt
awk '{ if (\$9 == \"AMR\") print \$1 }' ukb_InferredAncestry.txt > ids_AMR.txt
"
echo $cmd
dx run swiss-army-knife \
    -iin="${project}:${datadir}/king/ukbpc.txt" \
    -iin="${project}:${datadir}/king/ukb_popref.txt" \
    -iin="${project}:${datadir}/king/king_ancestry.r" \
    -icmd="${cmd}" \
    --destination="${project}:${datadir}/king" \
    --brief \
    --yes \
    --instance-type "mem1_ssd1_v2_x16"

    