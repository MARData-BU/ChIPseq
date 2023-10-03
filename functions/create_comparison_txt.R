samplesheet=commandArgs()[6]
bamDir=commandArgs()[7]
outputDir=commandArgs()[8]

print(samplesheet)

require(openxlsx)
samplesheet_xlsx <- read.xlsx(xlsxFile=samplesheet, sheet=2)


if (ncol(samplesheet_xlsx) > 3){
  dataframe_comparisons <- data.frame(matrix(data=NA, ncol=2, nrow=nrow(samplesheet_xlsx)*2))
  for (i in seq(1,nrow(samplesheet_xlsx)*2,by = 2)){
    comparison_data1 <- paste0(bamDir,"/CHIP/",samplesheet_xlsx[i,2],"_sorted.dedup.filtered.bam")
    comparison_data2 <- paste0(bamDir,"/INPUT/",samplesheet_xlsx[i,3],"_sorted.dedup.filtered.bam")
    comparison_data3 <- paste0(bamDir,"/MOCK/",samplesheet_xlsx[i,4],"_sorted.dedup.filtered.bam")
    dataframe_comparisons[i,1] <- comparison_data1
    dataframe_comparisons[i,2] <- comparison_data2
    dataframe_comparisons[i+1,1] <- comparison_data1
    dataframe_comparisons[i+1,2] <- comparison_data3
  }
}else if (ncol(samplesheet_xlsx) == 3){
  dataframe_comparisons <- data.frame(matrix(data=NA, ncol=2, nrow=nrow(samplesheet_xlsx)))
  for (i in 1:nrow(samplesheet_xlsx)){
    comparison_data1 <- paste0(bamDir,"/CHIP/",samplesheet_xlsx[i,2],"_sorted.dedup.filtered.bam")
    comparison_data2 <- paste0(bamDir,"/INPUT/",samplesheet_xlsx[i,3],"_sorted.dedup.filtered.bam")
    dataframe_comparisons[i,1] <- comparison_data1
    dataframe_comparisons[i,2] <- comparison_data2
  }
}

write.table(dataframe_comparisons, file = file.path(outputDir,"comparisons.txt"), row.names = F , col.names = F, quote = F)
