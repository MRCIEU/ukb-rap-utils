chr <- commandArgs(T)[1]

vfile <- paste0("variant_info_", chr, ".txt")
bfile <- paste0("ukb21007_c", chr, "_b0_v1")
bimfile <- paste0(bfile, ".bim")

a <- read.table(vfile, header=FALSE)
b <- read.table(bimfile, header=FALSE)

dim(a)
dim(b)
head(a)
head(b)

b$id <- paste(b$V1, b$V4, b$V5, b$V6)
a$id <- paste(gsub("chr", "", a$V1), a$V2, a$V5, a$V4)

table(a$id %in% b$id)
m <- match(b$id, a$id)

stopifnot(all(b$id == a$id[m], na.rm=T))
b$V2 <- a$V3[m]

head(b)
tail(b)

file.copy(bimfile, paste0(bimfile, ".noid"))

table(a$id %in% b$id)
table(b$id %in% a$id)

# Variants that are not in vcf check
ind <- is.na(b$V2)

bcheck <- read.table(paste0(bimfile, ".noid"), header=FALSE)
stopifnot(all(b$V4 == bcheck$V4))

# Update map
b$switch <- b$V5 > b$V6

rem <- b$V2[ind]
b$V2[b$switch] <- paste0(b$V1, ":", b$V4, "_", b$V6, "_", b$V5)[b$switch]
b$V2[!b$switch] <- paste0(b$V1, ":", b$V4, "_", b$V5, "_", b$V6)[!b$switch]
b$V2[ind] <- rem


# Remove variants with no ID
dup <- duplicated(b$V2)
table(dup)
table(ind)
ind <- ind | dup
table(ind)

b$V2[ind] <- paste0("miss_", 1:sum(ind))
head(b)
head(b[ind,])
to_remove <- subset(b, grepl("miss_", V2))$V2
head(to_remove)

tm <- tempfile()
remfile <- paste0(tm, ".toremove")
write.table(to_remove, file=remfile, row=F, col=F, qu=F)


# write bimfile
write.table(subset(b, select=c(V1, V2, V3, V4, V5, V6)), file=bimfile, row=F, col=F, qu=F)

bo <- b

temp <- b$V5[b$switch]
b$V5[b$switch] <- b$V6[b$switch]
b$V6[b$switch] <- temp
table(b$switch)

switchfile <- paste0(tm, ".switch")
write.table(subset(b, select=c(V2, V6)), file=switchfile, quote=FALSE, col.names=FALSE, row.names=FALSE, sep=" ")

cmd <- paste0("plink2 --bfile ", bfile, " --exclude ", remfile, " --ref-allele ", switchfile, " 2 1 --make-bed --keep-allele-order --out ", bfile)
cmd
system(cmd)

# Remove old version
system(paste0("rm -f ", bfile, "*~"))

# Create a version with rsids
b2 <- read.table(bimfile, header=FALSE)
head(b2)

temp1 <- merge(subset(a, select=c(V3, id)), subset(b, select=c(V2, id)))
head(temp1)
m1 <- match(b2$V2, temp1$V2)
stopifnot(all(b2$V2 == temp1$V2[m1]))

b2$V2 <- temp1$V3[m1]
head(b2)

table(is.na(b2$V2))
table(duplicated(b2$V2))
write.table(b2, file=paste0(bimfile, ".rsid"), row=F, col=F, qu=F)
