####################################################
-
################ ChIPseq PIPELINE ###################
-
####################################################
-
 
Bioinformatics analysis pipeline used for Chromatin ImmunopreciPitation sequencing (ChIP-seq) data. Required files are the following:

- config_input_files.txt file: Must be fulfilled leaving an empty space between the colon (:) and the input text (e.g: project_directory: /bicoh/MARGenomics/Development/RNASeq/TEST). Any other version of inputing data (such as project_directory:/bicoh/MARGenomics...) will NOT work for the pipeline.
- sample_sheet.xlsx file: Must be fulfilled the columns with the info of the project. Slide 1 = information about the fastq files. Slide 2 = information about the comparatives.

Be aware that the following modules/packages will need to be installed in your computer for the pipeline to run:

- bash: Picard, SAMtools, FastQ-Screen, FastQC, Python, Bowtie2, R, bedtools, cutadapt
- R: openxlsx

######################### FOLDERS #########################


- project_directory: /bicoh/MARGenomics/20230221_AriyJorge_ChipSeq (Project)
- project_info: /bicoh/MARGenomics/20230221_AriyJorge_ChipSeq/ProjectInfo (Folder where we can find the sample_sheet and other info)
- project_analysis: /bicoh/MARGenomics/20230221_AriyJorge_ChipSeq/Analysis (Folder for the Analysis)
- results: /bicoh/MARGenomics/20230221_AriyJorge_ChipSeq/Analysis/RESULTS (Folder for results)
- sample_sheet: /bicoh/MARGenomics/20230221_AriyJorge_ChipSeq/ProjectInfo/sample_sheet.xlsx (Excel with fastq files info to merge the different lanes)
- functions: /bicoh/MARGenomics/Development/ChIPSeq/Functions (where the functions of the pipeline are)

################## PIPELINE INFO ##########################

- merge: false (If you want to merge the Lanes of the fastq files for each sample)
- trimming: false (If you want to remove adapters or trim the fastq files)
- qc: false (FastQC and FastqScreen programms to evaluate the quality of the data)
- alignment: false (Bowtie2 to perform the alignment step)
- filtering: false (filter bam files)
- qc_peaks: false (Preseq, BigWig and PhantomPeak information about the bam files)
- mv_bams: false (Move the files into different folders to make the comparisons)
- peak_calling: true (Run the Peak Calling with EPIC2 and MACS2)

#################### ANNOTATION #######################

- genome: /bicoh/MARGenomics/Ref_Genomes_fa/GRCh38/GRCh38.primary_assembly.genome.fa
- annotation: /bicoh/MARGenomics/AnalysisFiles/Annot_files_GTF/Human/gencode.v41.primary_assembly.annotation.gtf
- index_bowtie2: /bicoh/MARGenomics/AnalysisFiles/Index_Genomes_Bowtie2/Human/GRCh38_ChIPSeq/GRCh38/GRCh38
- chrom_sizes: /bicoh/MARGenomics/Development/ChIPSeq/Functions/GRCh38.primary_assembly.genome.chrom.sizes

############# EXPERIMENT DESIGN ##############

- num_samples: 24

############# PEAKCALLING PARAMETERS ###########

- macs2_specie: hs
(macs2: -g GSIZE, --gsize GSIZE. Effective genome size. It can be 1.0e+9 or 1000000000, or shortcuts:'hs' for human (2.7e9), 'mm' for mouse (1.87e9), 'ce' for C.elegans (9e7) and 'dm' for fruitfly (1.2e8), Default:hs)

- epic2_specie: hg38
(epic2:  --genome GENOME, -gn GENOME. Which genome to analyze. Default: hg19. If --chromsizes and --egf flag is given, --genome is not required. Options in github (hg38, mm9, mm10..) :https://github.com/biocore-ntnu/epic2/tree/master/epic2/chromsizes)
