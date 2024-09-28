# Infer ancestry from UK Bioabank genotype data

- Obtain an LD pruned and QC'd dataset from the UK Biobank genotyped data
- Generate PCs in 1000 genomes
- Project PCs onto UK Biobank
- Use KING to assign ancestry (AFR, AMR, EAS, EUR, SAS)

Note that KING has issues running the SVD step to classify individuals from the PCs. The `king_ancestry.r` script is a fix for this issue.
