#!/bin/bash

source config.sh

# Extract UKB to plink with filters

dx upload update_chr.r --destination="${project}:/data/plink/" -p

for chr in {1..22}
do
cmd="
# Get the list of variants that pass the threshold
bcftools filter -e 'INFO/R2<0.8' /mnt/project/Bulk/Imputation/Imputation\ from\ genotype\ \(TOPmed\)/helper_files/ukb21007_c${chr}_b0_v1.sites.vcf.gz | \
bcftools filter -e 'INFO/AF<0.001' | \
bcftools filter -e 'INFO/AF>0.999' | \
bcftools query -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%AF\t%R2\n' > variant_info_${chr}.txt

cut -f 3 variant_info_${chr}.txt > variant_list_${chr}.txt
awk '{print \$1, \$2, \$2, \$3}' variant_info_${chr}.txt | sort | uniq -u > variant_info_${chr}.range
cut -f 3 variant_info_${chr}.txt > variant_list_${chr}.txt

# Extract from plink
plink2 \
    --bgen \"/mnt/project/Bulk/Imputation/Imputation from genotype (TOPmed)/ukb21007_c${chr}_b0_v1.bgen\" ref-first \
    --sample \"/mnt/project/Bulk/Imputation/Imputation from genotype (TOPmed)/ukb21007_c${chr}_b0_v1.sample\" \
    --extract range variant_info_${chr}.range \
    --maf 0.001 \
    --make-bed \
    --out ukb21007_c${chr}_b0_v1

# Remove SNPs with no ID, update alleles and variant IDs
Rscript /mnt/project/data/plink/update_chr.r ${chr}
"

echo $cmd
dx run swiss-army-knife \
    -icmd="${cmd}" \
    --destination="${project}:/data/plink" \
    --brief \
    --yes \
    --instance-type="mem2_ssd1_v2_x32"
done
