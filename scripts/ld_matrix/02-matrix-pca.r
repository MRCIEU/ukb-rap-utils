library(parallel)
library(data.table)

for(i in 1:22) {
    fn <- list.files(file.path("/local-scratch/projects/genotype-phenotype-map/data/ld_reference_panel_hg38/EUR", i), full.names=TRUE) %>% 
    grep("bed$", ., value=TRUE) %>% gsub(".bed", "", .)
# f <- fn[1]
    mclapply(fn, \(f) {
        if(!file.exists(glue("{f}.ldeig.rds"))) {
            message(f)
            ld <- fread(glue("{f}.unphased.vcor1"))
            # pc <- princomp(ld)
            e <- eigen(ld)
            saveRDS(e, file=glue("{f}.ldeig.rds"))
        }
    }, mc.cores=50)
}

