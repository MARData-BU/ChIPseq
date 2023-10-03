inputDir=commandArgs()[6]
samplesheet=commandArgs()[7]
outputDir=commandArgs()[8]

print(samplesheet)
print(inputDir)
print(outputDir)

require(openxlsx)

files_to_change <- list.files(inputDir)[grep(".fastq.gz",list.files(inputDir))]
order_files_to_change <- gsub(".fastq.gz", "",files_to_change)
samplesheet <- gsub("/home/ariadna", "", samplesheet)
inputDir <- gsub("/home/ariadna", "", inputDir)
samplesheet_xlsx <- read.xlsx(xlsxFile=samplesheet, sheet=1)
samplesheet_xlsx$X4 <- gsub(".fastq.gz", "", samplesheet_xlsx$X4)
samplesheet_xlsx$X4 <- basename(samplesheet_xlsx$X4)
samplesheet_xlsx.ordered <- samplesheet_xlsx[match(order_files_to_change,samplesheet_xlsx$X4),]
list_names <- list()
for (i in 1:nrow(samplesheet_xlsx.ordered)){
  name <- samplesheet_xlsx.ordered[i,1]
  type <- samplesheet_xlsx.ordered[i,2]
  thisfile <- files_to_change[grep(name,files_to_change)]
  create_name <- paste0(name,"_",type,".fastq.gz")
  list_names[[i]] <- create_name
  file.rename(file.path(inputDir,files_to_change[i]),file.path(outputDir,create_name))
}
