library(data.table)
a <- fread("ld_regions_hg38.tsv")
b <- fread("ld_blocks.tsv")

ind1 <- paste(a$chr, a$start, a$end, a$ancestry)
ind2 <- paste(b$chr, b$start, b$stop, b$ancestry)

b1 <- b[! ind2 %in% ind1,]
write.table(b1, "missing_blocks.txt", quote = F, row.names = F, col.names = T, sep = "\t")
