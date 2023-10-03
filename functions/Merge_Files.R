
samplesheet=commandArgs()[6]
outputDir=commandArgs()[7]

print(samplesheet)
print(outputDir)

require(openxlsx)


zcat <- read.xlsx(xlsxFile = samplesheet , sheet=1)


true_cases <- length(which(apply(zcat,2,complete.cases)==T))

list.paste <- list()
list.paste[[1]] <- "#!/bin/bash"
list.paste[[2]] <- "#SBATCH -p long,short,normal"
list.paste[[3]] <- "#SBATCH --cpus-per-task=6"
list.paste[[4]] <- "#SBATCH --mem-per-cpu 8Gb"
list.paste[[5]] <- "#SBATCH -J create_merge_file"
list.paste[[6]] <- "#SBATCH -o logs/runR.%J.out"
list.paste[[7]] <- "#SBATCH -e logs/runR.%J.err"

for (i in 1:nrow(zcat)){
  true_cases <- length(which(apply(zcat[i,4:ncol(zcat)],2,complete.cases)==T))
  fastqfiles <- zcat[i,4:(3+true_cases)]
  list.paste[[i+7]] <- paste0("zcat ", fastqfiles," >> ", outputDir, "/", zcat$sample_name[i] ,"_", zcat$Type[i], ".fastq" )
  list.paste[[i+7]] <- paste(list.paste[[i+7]], collapse=";")
}

write.table(x=unlist(list.paste),quote=FALSE,sep="\n", file=file.path(outputDir,"merge_to_run.sh"),row.names = F, col.names = F)
