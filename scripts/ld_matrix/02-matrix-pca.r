library(parallel)
library(data.table)
library(dplyr)
library(glue)

# Generate LD matrices from region bfiles
# for(i in 1:22) {
#     fn <- list.files(file.path("/local-scratch/projects/genotype-phenotype-map/data/ld_reference_panel_hg38/EUR", i), full.names=TRUE) %>% 
#     grep("bed$", ., value=TRUE) %>% gsub(".bed", "", .)
#     for(f in fn) {
#         if(file.exists(glue("{f}.unphased.vcor1")))
#         {
#             file.copy(glue("{f}.unphased.vcor1"), glue("{f}.old.unphased.vcor1"))
#         }
#         cmd <- glue("plink2 --bfile {f} --r-unphased square ref-based --keep-allele-order --out {f}")

#         cmd %>% system()
#     }
# }


i <- 21
for(i in 1:22) {
    fn <- list.files(file.path("missing", i), full.names=TRUE) %>% 
    grep("bed$", ., value=TRUE) %>% gsub(".bed", "", .)
# f <- fn[1]
    if(length(fn) > 0) {
        mclapply(fn, \(f) {
            if(!file.exists(glue("{f}.ldeig.rds"))) {
                message(f)
                ld <- fread(glue("{f}.unphased.vcor1"))
                # pc <- princomp(ld)
                e <- eigen(ld)
                saveRDS(e, file=glue("{f}.ldeig.rds"))
            }
        }, mc.cores=2)
    }
}

