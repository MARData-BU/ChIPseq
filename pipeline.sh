#!/bin/bash
#SBATCH -p normal,long,bigmem         # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 10Gb     # Memory in MB
#SBATCH -J Chipseq           # job name
#SBATCH -o logs/Chipseq.%J.out    # File to which standard out will be written
#SBATCH -e logs/Chipseq.%J.err    # File to which standard err will be written

echo -e "
#####################################################################
#############                                           #############
#############             CHIP-SEQ PIPELINE             #############
#############                                           #############
#####################################################################
"
#### 1_Get all the paths from the congif_inputs_files.txt: It has to be a .txt file with specefic structure (check the example: /bicoh/MARGenomics/Development/ChIPSeq/config_inputs_files.txt)

echo -e "\n\nStarting analysis... \n\n"
PARAMS=$1

# PROJECT INFO IN GENERAL:
PROJECT=$(grep project_directory: $PARAMS | awk '{ print$2 }')
WD=$(grep project_analysis: $PARAMS | awk '{ print$2 }')
FUNCTIONSDIR=$(grep functions: $PARAMS | awk '{ print$2 }')
PROJECTINFO=$(grep project_info: $PARAMS | awk '{ print$2 }')
OUTPUT=$(grep results: $PARAMS | awk '{ print$2  }')
SAMPLE_SHEET=$(grep sample_sheet: $PARAMS | awk '{ print$2 }')


# ANNOTATIONS:
GENOME=$(grep genome: $PARAMS | awk '{ print$2 }')
INDEX_BOWTIE2=$(grep index_bowtie2: $PARAMS | awk '{ print$2 }')
CHROM_SIZES=$(grep chrom_sizes: $PARAMS | awk '{ print$2 }')


# IMPORTANT INFORMATION ABOUT THE DESIGN OF THE EXPERIMENT:
NUM_SAMPLES=$(grep num_samples: $PARAMS | awk '{ print$2 }') # total number of samples AFTER THE MERGE and for each batch

COMPARISONS=$(grep comparisons: $PARAMS | awk '{ print$2  }')

# PARAMETERS OF THE SPECIE GENOME SIZE FOR PEAK CALLING PART:
macs2_specie=$(grep macs2_specie: $PARAMS | awk '{ print$2 }')
epic2_specie=$(grep epic2_specie: $PARAMS | awk '{ print$2 }')

# Pipeline:
MERGE=$(grep merge: $PARAMS | awk '{ print$2  }')
TRIM=$(grep trimming: $PARAMS | awk '{ print$2  }')
QC=$(grep qc: $PARAMS | awk '{ print$2  }')
ALIGN=$(grep alignment: $PARAMS | awk '{ print$2  }')
FILTER=$(grep filtering: $PARAMS | awk '{ print$2  }')
MRG_ALIGN="false"
QC_PEAK=$(grep qc_peaks: $PARAMS | awk '{ print$2  }')
PEAK_CALL=$(grep peak_calling: $PARAMS | awk '{ print$2  }')
MV_BAMS=$(grep mv_bams: $PARAMS | awk '{print$2 }')
MACS=$(grep MACS: $PARAMS | awk '{print$2 }')
EPIC=$(grep EPIC: $PARAMS | awk '{print$2 }')
BIGBED=$(grep bigbed: $PARAMS | awk '{print$2 }')
ADAPTER=$(grep adapter: $PARAMS | awk '{print$2 }')

# Batch
FASTQDIR=$(grep fastqdir: $PARAMS | awk '{print$2 }')
BATCH=$(grep batch_num: $PARAMS | awk '{print$2 }')
BATCH_FOLDER=$(grep batch_folder: $PARAMS | awk '{print$2 }')
FASTQ_SUFFIX=$(grep fastq_suffix: $PARAMS | awk '{print$2 }')

echo -e "Batch folder is $BATCH_FOLDER"
echo -e "Batch number is $BATCH"
# Convert BATCH to an integer
BATCH=$((BATCH))

# If batch number is greater than 1, define the batch folders by merging the batch prefix with the number of batches
if [ $BATCH -gt 1 ]; then
  folders=()
  for ((n=1; n<=$BATCH; n++)); do
    folder="${BATCH_FOLDER}${n}"
    folders+=("$folder")
  done

  echo "- The batch prefix is: $BATCH_FOLDER, and the batch folders are:"
  for folder in "${folders[@]}"; do
    echo "  - $folder"
    # Use the folder variable as needed
  done

elif [ $BATCH -eq 1 ]; then
  folders=()
  if [ "$BATCH_FOLDER" == "NA" ] || [ "$BATCH_FOLDER" == "FALSE" ]; then
    folders+=("/")
    echo -e "There is no folder name for the batch (1)."
  else
    folders+=("$BATCH_FOLDER")
    echo -e "The folder name for the batch (1) is $BATCH_FOLDER."
  fi

else
  echo "Invalid BATCH value: $BATCH"
fi



##Printing variable values

echo -e "Reading input variables:\n"
echo -e "  ###" SAMPLE_SHEET=$SAMPLE_SHEET
echo -e "  ###" WORKING_DIRECTORY=$WD
echo -e "  ###" FUNCTIONS_DIR=$FUNCTIONSDIR
echo -e "  ###" PROJECT=$PROJECT
echo -e "  ###" PROJECTINFO=$PROJECTINFO
echo -e "  ###" GENOME=$GENOME
echo -e "  ###" NUMBER_CHIP_SAMPLES=$NUMCHIP
echo -e "  ###" NUMBER_INPUT_SAMPLES=$NUMINPUT
echo -e "  ###" NUMBER_MOCK_SAMPLES=$NUMMOCK
echo -e "  ###" OUTPUT=$OUTPUT
echo -e "  ###" TOTAL_BATCHES=$BATCH
echo -e "  ###" BATCH_FOLDER=$BATCH_FOLDER

echo -e "  ###" MERGE=$MERGE
echo -e "  ###" TRIMMING=$TRIM
echo -e "  ###" QC=$QC
echo -e "  ###" ALIGN=$ALIGN
echo -e "  ###" FILTER=$FILTER
echo -e "  ###" QC_PEAK=$QC_PEAK
echo -e "  ###" PEAK_CALL=$PEAK_CALL
echo -e "  ###" MV_BAMS=$MV_BAMS
echo -e "  ###" MACS=$MACS
echo -e "  ###" EPIC=$EPIC
echo -e "  ###" BIGBED=$BIGBED
echo -e "  ###" ADAPTER=$ADAPTER #adapter seqs can be found in https://github.com/vsbuffalo/scythe/blob/master/illumina_adapters.fa
echo -e "  ###" COMPARISONS=$COMPARISONS
echo -e "  ###" NUM_SAMPLES=$NUM_SAMPLES # total number of samples after the merge (if applicable) or just total number of samples. This is BY BATCH. Include MOCK and/or INPUT samples.


echo -e "\n\nAccording to the set up, the steps to perform are:"

if [ $MERGE == "true" ]
then
  echo -e "\n\n -Create script to concatenate FASTQ files\n"
fi

if [ $TRIM == "true" ]
then
  echo -e " -Trimming FASTQ files\n"
fi

if [ $QC == "true" ]
then
  echo -e " -QC on FASTQ files\n"
fi

if [ $ALIGN == "true" ]
then
  echo -e " -Alignment\n"
fi

if [ $QC_PEAK == "true" ]
then
  echo -e " -QC on alignment\n"
fi

if [ $PEAK_CALL == "true" ]
then
  echo -e " -Peak calling\n"
fi

#### 2_Genearate specific directories with an specific structure. It has to be always the same structure in order to run the pipeline:

#Create:
# data folder: where the concatenated fastq files will be created with new names. For example: RCC_D1_LANE1.fastq, RCC_D1_LANE2.fastq will be: RCC_D1_chip.fastq
# results folder: where the results will be placed

mkdir -p $WD
mkdir -p $OUTPUT
mkdir -p $PROJECT/QC
mkdir -p $PROJECTINFO
cd $WD

## Creating directories
mkdir Results logs

#echo '#!/bin/bash' > ${WD}/DATA/merge_to_run.sh

#### 3_Concatenate raw data using R script

if [ $MERGE == "true" ]
then
for folder in "${folders[@]}"; do
    mkdir -p $WD/Merged_data/${folder}
    chmod 777 $WD/Merged_data/${folder} # solve permission problems
    echo -e "\n\nCreating the script to concatenate the FASTQ files...\n\n"

    sbatch $FUNCTIONSDIR/create_merge_file.sh $FUNCTIONSDIR $SAMPLE_SHEET $WD/Merged_data/${folder}
    chmod 777 $WD/Merged_data/${folder}/merge_to_run.sh # solve permission problems

    until [ -f $WD/Merged_data/${folder}/merge_to_run.sh ] # Wait until merge_to_run.sh created.
    do
        echo -e "merge_to_run.sh file does not yet exist. Sleeping for 5 seconds..."
        sleep 5 # wait 5 seconds
    done

    echo "File found"

    echo -e "\n\nMerging FASTQ files...\n\n"

    sbatch --dependency=$(squeue --noheader --format %i --name create_merge_file) $WD/Merged_data//${folder}/merge_to_run.sh

    echo -e "\n\nCompressing FASTQ files...\n\n"

    if ls $WD/Merged_data/${folder}/*.fastq >/dev/null 2>&1 # check whether there is any .fastq file
    then
        count=`ls -l $WD/Merged_data/${folder}/*.fastq | wc -l`
        while [ $count != $NUM_SAMPLES ] # check whether ALL the files corresponding to every sample are created or not
        do
          sleep 100 # wait if not
          count=`ls -l $WD/Merged_data/${folder}/*.fastq | wc -l` # check again
          echo "The number of fastq files is $count"
      done
    else
        echo "There are no merged fastq files yet. Sleeping for 300 seconds..."
        sleep 300 # if there is no fastq file, sleep for 300 seconds so some fastq file will be generated
        count=`ls -l $WD/Merged_data/${folder}/*.fastq | wc -l`
        while [ $count != $NUM_SAMPLES ] # check whether ALL the files corresponding to every sample are created or not
        do
          sleep 100 # wait if not
          count=`ls -l $WD/Merged_data/${folder}/*.fastq | wc -l` # check again
          echo "The number of fastq files is $count and it should be $NUM_SAMPLES"
      done
    fi

    echo "All done, there are a total of $count fastq files and it should be $NUM_SAMPLES. Sleeping for 300 seconds so the files are properly filled."

    sleep 300 # sleep to ensure that all files have been generated and filled.

    num_files=$(ls -1 "$WD/Merged_data"/${folder}/*.fastq | wc -l)
    JOB_GZIP=$(sbatch --array=1-$num_files --parsable "$FUNCTIONSDIR/gzip.sh" "$WD/Merged_data/${folder}")
    echo "Gzip jobs sent, sleeping for 300 seconds..."
    sleep 300

    count=`ls -l $WD/Merged_data/${folder}/*${FASTQ_SUFFIX} | wc -l` # check number of compressed files
    echo "The number of fastq.gz files is $count and it should be $num_files."

    JOB_ID=$(echo "$JOB_GZIP" | cut -d' ' -f1)

    # Keep checking if any job from the array is still running
    while squeue --job="$JOB_ID" | grep -q "$JOB_ID"; do
        echo "Some gzip jobs are still running. Sleeping for 200 seconds..."
        sleep 200
    done

    # Check whether ALL files have been compressed, if not, compress them
    while [ "$count" -ne "$num_files" ]; do
        echo "Mismatch detected. Checking for uncompressed .fastq files..."

        # Find and compress any remaining .fastq files
        find "$WD/Merged_data/${folder}" -type f -name "*.fastq" -exec gzip {} \;

        # Recheck count
        count=$(ls -l $WD/Merged_data/${folder}/*${FASTQ_SUFFIX} 2>/dev/null | wc -l)
        echo "The number of fastq.gz files is $count and it should be $num_files."

        # Sleep before rechecking
        sleep 300
    done

    echo -e "\n\nFastQ Files compressed\n\n"
    done

else
  for folder in "${folders[@]}"; do

    if ls ${WD}/Merged_data/${folder}/*${FASTQ_SUFFIX} >/dev/null 2>&1 # check whether there is any .fastq.gz files (there will be if the pipeline has been run previously)
      then
      samples="$(ls "${WD}/Merged_data/${folder}"/*"${FASTQ_SUFFIX}")"
      echo -e "The fastq.gz files are already in the Merged_data folder. Specifically, they are"
      for file in $samples; do
        echo "$file"
      done
    else
    mkdir -p ${WD}/Merged_data/${folder}
    cp ${FASTQDIR}/${folder}/*${FASTQ_SUFFIX} ${WD}/Merged_data/${folder} # create hyperlink of the fastq files. If the pipeline has been previously run this will fail but it's ok.
    sleep 500 # sleep for 500 seconds to ensure that the files copied are filled
    echo -e "\n\nChanging fastQ Files names\n\n"
    sbatch ${FUNCTIONSDIR}/fastq_files_names.sh $FUNCTIONSDIR $SAMPLE_SHEET ${FASTQDIR}/${folder} ${WD}/Merged_data/${folder} # this step will fail if the pipeline has been previously launched as the fastq files are moved. This will NOT cause the whole pipeline to fail, though.
    fi
  done
fi

#### 4_Trimming:

if [ $TRIM == "true" ]
then
  for folder in "${folders[@]}"; do
    INPUT_DATA=${WD}/Merged_data/${folder}

    echo -e "\n\nTrimming FASTQ files...\n\n"
    mkdir $INPUT_DATA/DATA_Trimmed
    INPUT_DATA_TRIM=$INPUT_DATA/DATA_Trimmed # change the data directory for the one with trimmed data
    num_files=$(ls -l $INPUT_DATA/*${FASTQ_SUFFIX} | wc -l)
    JOB_CUTADAPT=$(sbatch --array=1-$num_files --parsable $FUNCTIONSDIR/cutadapt.sh $INPUT_DATA $INPUT_DATA_TRIM $ADAPTER ) # --parsable means that we need to save the job_id as a variable. It is necessary in order to keep running the pipeline, because we need to finish this step in order to start the others.
    echo -e "Notice that from now on, trimmed data will be used for the analysis\n\n"
  done
else
    echo -e "No trimming step was performed\n\n"
fi

#### 4_Quality Control: FASTQC and FASTQScreen + multiQC

if [ "$QC" == "true" ]; then
  for folder in "${folders[@]}"; do
    if test -d "${WD}/Merged_data/${folder}/DATA_Trimmed"; then
      INPUT_DATA="${WD}/Merged_data/${folder}/DATA_Trimmed"
    else
      INPUT_DATA="${WD}/Merged_data/${folder}"
    fi

    echo -e "Data for QC will be taken from $INPUT_DATA."
    echo -e "\n\nStarting QC for batch $folder...\n\n"

    mkdir -p "$OUTPUT/QC/${folder}"
    QCDIR="$OUTPUT/QC/${folder}"

    if ls $INPUT_DATA/*.fastq.gz >/dev/null 2>&1 # check whether there is any .fastq.gz (if trimming is being performed, there might not be any yet)
      then
      count=`ls -l $INPUT_DATA/*.fastq.gz | wc -l`
      files_needed=`ls -l ${WD}/Merged_data/${folder}/*.fastq.gz | wc -l`

      while [ $count != $files_needed ] # check whether ALL the files corresponding to every sample are created or not
        do
          echo "The number of fastq.gz files is $count, and it needs to be $files_needed. Sleeping for 100 seconds so the required files are generated..."
          sleep 100 # wait if not
          count=`ls -l $INPUT_DATA/*.fastq.gz | wc -l`
      done
    else
      echo -e "There are no fastq.gz files yet. Sleeping for 10 minutes so some files are generated..."
      sleep 600 # sleep 10 minutes so some fastq.gz files are generated

      count=`ls -l $INPUT_DATA/*.fastq.gz | wc -l`
      files_needed=`ls -l ${WD}/Merged_data/${folder}/*.fastq.gz | wc -l`

      while [ $count != $files_needed ] # check whether ALL the files corresponding to every sample are created or not
        do
          echo "The number of fastq.gz files is $count, and it needs to be $files_needed. Sleeping for 200 seconds so the required files are generated..."
          sleep 200 # wait if not
          count=`ls -l $INPUT_DATA/*.fastq.gz | wc -l`
      done

      num_files=$(ls -l $INPUT_DATA/*.fastq.gz | wc -l)

      echo -e "Sleeping 500 seconds so the fastq.gz files are filled..."
      sleep 500 # give time so the fastq.gz files are filled

    fi

    if [ "$TRIM" == "true" ]; then
      num_files=$(ls -l "$INPUT_DATA"/*.fastq.gz | wc -l)
      echo -e "\n\nQC on trimmed data...\n\n"
      JOB_QC=$(sbatch --array=1-$num_files --dependency=afterok:${JOB_CUTADAPT} --parsable "${FUNCTIONSDIR}/QC.sh" "${INPUT_DATA}" "${QCDIR}") # Wait until cutadapt is done. It is not necessary --parsable because none of the following scripts required to finish the qc.
    else
      num_files=$(ls -l "$INPUT_DATA"/*.fastq.gz | wc -l)
      echo -e "\n\nQC on data...\n\n"
      JOB_QC=$(sbatch --array=1-$num_files --parsable "${FUNCTIONSDIR}/QC.sh" "${INPUT_DATA}" "${QCDIR}") # else, run it
    fi

    if [ -n "$JOB_QC" ]; then
      echo -e "QC jobs sent with IDs ${JOB_QC}."
      QCDIR="${OUTPUT}/QC/${folder}"
      sbatch --dependency=afterany:${JOB_QC} "${FUNCTIONSDIR}/multiQC.sh" "$QCDIR"
    else
      echo "Error: QC jobs were not submitted successfully."
    fi
  done
fi

#### 5.A_Alignment (BOWTIE2)

if [ $ALIGN == "true" ]
then
  for folder in "${folders[@]}"; do
    if test -d ${WD}/Merged_data/${folder}/DATA_Trimmed # check if the directory for the trimmed data exists
      then
        INPUT_DATA=${WD}/Merged_data/${folder}/DATA_Trimmed
      else
        INPUT_DATA=${WD}/Merged_data/${folder}
    fi

    mkdir -p $OUTPUT/BAM_Files/${folder}
    BAMDIR=$OUTPUT/BAM_Files/${folder}

    echo -e "\n\nStarting alignment with BOWTIE2 for batch $folder...\n\n"

    num_files=$(ls -l $INPUT_DATA/*.fastq.gz | wc -l)

    if [ $TRIM == "true" ]
    then
      echo -e "\n\nAligning trimmed data...\n\n"
      JOB_ALIGN=$(sbatch --array=1-$num_files --dependency=afterok:${JOB_CUTADAPT} --parsable ${FUNCTIONSDIR}/bowtie2.sh $INPUT_DATA $BAMDIR $INDEX_BOWTIE2 $GENOME) # Wait until cutadapt is done. It is necessary to include --parsable because the alingment is a main step that has to be finished in order to keep running.
    else
      echo -e "\n\nAligning data...\n\n"
      JOB_ALIGN=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/bowtie2.sh $INPUT_DATA $BAMDIR $INDEX_BOWTIE2 $GENOME) # else, run it. It is necessary the --parsable option for keep running
    fi

    if [ -n "$JOB_ALIGN" ]; then
      echo -e "Alignment jobs sent with IDs ${JOB_ALIGN}."
    else
      echo "Error: align jobs were not submitted successfully."
    fi
    JOB_ALIGN_LIST+=($JOB_ALIGN)
  done
fi

if [ $FILTER == "true" ]
then
echo -e "Filtering samples"
  for folder in "${folders[@]}"; do
    if test -d ${WD}/Merged_data/${folder}/DATA_Trimmed # check if the directory for the trimmed data exists
      then
        INPUT_DATA=${WD}/Merged_data/${folder}/DATA_Trimmed
      else
        INPUT_DATA=${WD}/Merged_data/${folder}
    fi

    BAMDIR=$OUTPUT/BAM_Files/${folder}
    echo -e "Bam directory has been defined as $BAMDIR"

    if ls $BAMDIR/*_sorted.bam >/dev/null 2>&1 # check whether there is any ._sorted.bam file (if alignment is being performed, there might not be any yet)
      then
      count=`ls -l $BAMDIR/*_sorted.bam | wc -l`
      files_needed=`ls -l $INPUT_DATA/*.fastq.gz | wc -l`

      while [ $count != $files_needed ] # check whether ALL the files corresponding to every sample are created or not
        do
          echo "The number of BAM files is $count, and it needs to be $files_needed. Sleeping for 100 seconds so the required files are generated..."
          sleep 100 # wait if not
          count=`ls -l $BAMDIR/*_sorted.bam | wc -l`
      done

      num_files=$(ls -l $BAMDIR/*_sorted.bam | wc -l)

      echo -e "Sleeping for 500 seconds so the sorted_bam files are filled..."
      sleep 500 # give time so the sorted_bam files are filled

    else
      echo -e "There are no sorted_bam files yet. Sleeping for 30 minutes so some files are generated..."
      sleep 1800 # sleep 30 minutes so some _sorted.bam files are generated

      count=`ls -l $BAMDIR/*_sorted.bam | wc -l`
      files_needed=`ls -l $INPUT_DATA/*.fastq.gz | wc -l`

      while [ $count != $files_needed ] # check whether ALL the files corresponding to every sample are created or not
        do
          echo "The number of BAM files is $count, and it needs to be $files_needed. Sleeping for 200 seconds so the required files are generated..."
          sleep 200 # wait if not
          count=`ls -l $BAMDIR/*_sorted.bam | wc -l`
      done

      num_files=$(ls -l $BAMDIR/*_sorted.bam | wc -l)

      echo -e "Sleeping 500 seconds so the sorted_bam files are filled..."
      sleep 500 # give time so the sorted_bam files are filled

    fi

    if [ $ALIGN == "true" ]
    then
        JOB_FILTER_BAM=$(sbatch --array=1-$num_files --dependency=afterok:${JOB_ALIGN_LIST[@]} --parsable ${FUNCTIONSDIR}/bam_filtering.sh $BAMDIR)
        echo -e "Filtering jobs sent with ID $JOB_FILTER_BAM."

      else
        num_files=$(ls -l $BAMDIR/*_sorted.bam | wc -l)
        JOB_FILTER_BAM=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/bam_filtering.sh $BAMDIR)
        echo -e "Filtering jobs sent with ID $JOB_FILTER_BAM."
    fi
    if [ -n "$JOB_FILTER_BAM" ]; then
      echo -e "BAM filtering jobs sent with IDs ${JOB_FILTER_BAM}."
    else
      echo "Error: BAM filtering jobs were not submitted successfully."
    fi
  done
fi

#### 5.B_Merge alignment (samtools): !!!!!!!!!!!!!!!!! IMPORTANT TO CHANGE THE HEADER OF THE PIPELINE AND ADD TO CONFIG FILE INFO ABOUT NUMREP
#if [ $MRG_ALIGN == "true" ]
#then
#mkdir $BAMDIR/Merged_BAMS
#MERGED_BAMS_DIR=$BAMDIR/Merged_BAMS
#  if [ $ALING == "true" ]
#  then
#    JOB_MERGE_BAM=$(sbatch --array=1-$num_rep --dependency=afterok:${JOB_FILTER_BAM} --parsable ${FUNCTIONSDIR}/merge_bams.sh $BAMDIR $num_rep $PARAMS $MERGED_BAMS_DIR)
#  else
#    JOB_MERGE_BAM=$(sbatch --array=1-$num_rep --parsable ${FUNCTIONSDIR}/merge_bams.sh $BAMDIR $num_rep $PARAMS $MERGED_BAMS_DIR)
#  fi
#fi


#### 5.C_QC

if [ $QC_PEAK == "true" ]
then
  for folder in "${folders[@]}"; do
    BAMDIR=$OUTPUT/BAM_Files/${folder}
    mkdir $BAMDIR/PRESEQ
    PRESEQDIR=$BAMDIR/PRESEQ
    mkdir $BAMDIR/BigWig
    BIGWIGDIR=$BAMDIR/BigWig
    mkdir $BAMDIR/Phantompeakqualtools
    PHANTOMDIR=$BAMDIR/Phantompeakqualtools

    if test -d ${WD}/Merged_data/${folder}/DATA_Trimmed # check if the directory for the trimmed data exists
      then
        INPUT_DATA=${WD}/Merged_data/${folder}/DATA_Trimmed
      else
        INPUT_DATA=${WD}/Merged_data/${folder}
    fi

    num_files=$(ls -l $INPUT_DATA/*.fastq.gz | wc -l) # check number of fastq files in INPUT_DATA directory, which will be different depending on whether data has been trimmed or not

    if [ $FILTER == "true" ]
    #### 6_Estimation library complexity
    then
      echo -e "\n\nStarting QC once the filtering is done...\n\n"
      echo -e "\n\nStarting PRESEQ (metrics for alignment)...\n\n"
      JOB_PRESEQ=$(sbatch --array=1-$num_files --dependency=afterany:${JOB_FILTER_BAM} --parsable ${FUNCTIONSDIR}/preseq.sh $BAMDIR $PRESEQDIR)
      echo -e "PRESEQ jobs sent with ID $JOB_PRESEQ."
      # it is necessary to include dependencies and --parsable because we have to wait the bam files.

      #### 7_Create normalized BigWig files for peak visualization

      echo -e "\n\nStarting BIGWIG (creating file for peak visualization)...\n\n"
      JOB_BIGWIG=$(sbatch --array=1-$num_files --dependency=afterany:${JOB_FILTER_BAM} --parsable ${FUNCTIONSDIR}/bedtools_bigwig.sh $BAMDIR $BIGWIGDIR $FUNCTIONSDIR $CHROM_SIZES)
      echo -e "BIGWIG jobs sent with ID $JOB_BIGWIG."
      # it is necessary to include dependencies and --parsable because we have to wait the bam files.

      #### 9_NSC and RSC (phantompeakqualtools)

      echo -e "\n\nStarting PHANTOM PEAK QUALTOOLS (metrics for alignment)...\n\n"
      JOB_PHANTOM=$(sbatch --array=1-$num_files --dependency=afterany:${JOB_FILTER_BAM} --parsable ${FUNCTIONSDIR}/phantompeakqualtools.sh $BAMDIR $PHANTOMDIR $FUNCTIONSDIR)
      echo -e "PHANTOM jobs sent with ID $JOB_PHANTOM."
      # it is necessary to include dependencies and --parsable because we have to wait the bam files.

    else
      echo -e "\n\nStarting PRESEQ (metrics for alignment)...\n\n"
      JOB_PRESEQ=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/preseq.sh $BAMDIR $PRESEQDIR)
      echo -e "PRESEQ jobs sent with ID $JOB_PRESEQ."
      # it is necessary to include dependencies and --parsable because we have to wait the bam files.

      #### 7_Create normalized BigWig files for peak visualization

      echo -e "\n\nStarting BIGWIG (creating file for peak visualization)...\n\n"
      JOB_BIGWIG=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/bedtools_bigwig.sh $BAMDIR $BIGWIGDIR $FUNCTIONSDIR)
      echo -e "BIGWIG jobs sent with ID $JOB_BIGWIG."
      # it is necessary to include dependencies and --parsable because we have to wait the bam files.

      #### 9_NSC and RSC (phantompeakqualtools)

      echo -e "\n\nStarting PHANTOM PEAK QUALTOOLS (metrics for alignment)...\n\n"
      JOB_PHANTOM=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/phantompeakqualtools.sh $BAMDIR $PHANTOMDIR $FUNCTIONSDIR)
      echo -e "PHANTOM jobs sent with ID $JOB_PHANTOM."
      # it is necessary to include dependencies and --parsable because we have to wait the bam files.
    fi
  done
  else
    echo -e "QC is false"
fi

#### 10.B_Move BAMFiles:
if [ $MV_BAMS == "true" ]
then
  for folder in "${folders[@]}"; do
      BAMDIR=$OUTPUT/BAM_Files/${folder}
    if [ $QC_PEAK == "true" ]
      then
          echo -e "\n\nClassifying BAM files into appropiate folder (input, chip and mock)...\n\n"
          JOB_MV=$(sbatch --dependency=afterany:${JOB_PRESEQ},${JOB_BIGWIG},${JOB_PHANTOM} --parsable ${FUNCTIONSDIR}/move_bamfiles.sh $BAMDIR)
          # it is necessary to include dependencies and --parsable because we have to wait before starting the peak calling due to the fact that we are moving the bam files depending on the type of sample
      else
          echo -e "\n\nClassifying BAM files into appropiate folder (input, chip and mock)...\n\n"
          JOB_MV=$(sbatch --parsable ${FUNCTIONSDIR}/move_bamfiles.sh $BAMDIR)
          # it is necessary to include dependencies and --parsable because we have to wait before starting the peak calling due to the fact that we are moving the bam files depending on the type of sample
      fi
  done
else
  echo -e "MV BAMS is false"
fi

#=================#
#   MultiQC       #
#=================#
for folder in "${folders[@]}"; do
  QCDIR=${OUTPUT}/QC/${folder}
  if [ $MV_BAMS == "true" ]
  then
    sbatch --dependency=afterany:${JOB_MV} ${FUNCTIONSDIR}/multiQC.sh ${QCDIR}
  else
    sbatch ${FUNCTIONSDIR}/multiQC.sh ${QCDIR}
  fi
done

#### 10.A_Peak Calling:

for folder in "${folders[@]}"; do
  if [ $PEAK_CALL == "true" ]
  then
  BAMDIR=$OUTPUT/BAM_Files/${folder}
  mkdir ${PROJECTINFO}/${folder}
      if [ $MV_BAMS == "true" ]
      then
        JOB_COMP=$(sbatch --dependency=afterany:${JOB_MV} --parsable ${FUNCTIONSDIR}/create_comparison_txt.sh ${SAMPLE_SHEET} ${BAMDIR} ${PROJECTINFO}/${folder} ${FUNCTIONSDIR})
      else
        JOB_COMP=$(sbatch --parsable ${FUNCTIONSDIR}/create_comparison_txt.sh ${SAMPLE_SHEET} ${BAMDIR} ${PROJECTINFO}/${folder} ${FUNCTIONSDIR})
      fi
      if [ $MACS == "true" ]
      then
      # MACS 2
      mkdir -p $OUTPUT/PEAK_CALLING/${folder}
      mkdir -p $OUTPUT/PEAK_CALLING/${folder}/MACS2
      MACSDIR=$OUTPUT/PEAK_CALLING/${folder}/MACS2
      mkdir ${MACSDIR}/CHIP_INPUT
      mkdir ${MACSDIR}/CHIP_MOCK
      MOCKDIR=${MACSDIR}/CHIP_MOCK
      INPUTDIR=${MACSDIR}/CHIP_INPUT
      echo -e "Running MACS2"
      JOB_MACS=$(sbatch --dependency=afterany:${JOB_COMP} --parsable ${FUNCTIONSDIR}/MACS2_run.sh ${PROJECTINFO}/${folder} ${MACSDIR} ${BAMDIR}/Phantompeakqualtools $macs2_specie ${FUNCTIONSDIR})
      fi

      if [ $EPIC == "true" ]
      then
      # EPIC 2
      mkdir -p $OUTPUT/PEAK_CALLING/${folder}/EPIC2
      EPICDIR=$OUTPUT/PEAK_CALLING/${folder}/EPIC2
      mkdir ${EPICDIR}/CHIP_INPUT
      mkdir ${EPICDIR}/CHIP_MOCK
      MOCKDIR=${EPICDIR}/CHIP_MOCK
      INPUTDIR=${EPICDIR}/CHIP_INPUT
      echo -e "Running EPIC2"
      JOB_EPIC=$(sbatch --dependency=afterany:${JOB_COMP} --parsable ${FUNCTIONSDIR}/EPIC2_run.sh ${PROJECTINFO}/${folder} ${EPICDIR} ${BAMDIR}/Phantompeakqualtools $epic2_specie $CHROM_SIZES ${FUNCTIONSDIR})
      fi
  fi
done


#### 11. BIG BEDS:


if [ $BIGBED == "true" ]
then
	if [ -d $OUTPUT/PEAK_CALLING/MACS2/CHIP_INPUT ] || [ -d $OUTPUT/PEAK_CALLING/EPIC2/CHIP_INPUT ]
	then
	if [ $PEAK_CALL == "true" ]
	then
    MACSDIR=$OUTPUT/PEAK_CALLING/MACS2
    EPICDIR=$OUTPUT/PEAK_CALLING/EPIC2

		if [ $MACS == "true" ]
    		then
          num_files=$(ls -l ${MACSDIR}/CHIP_INPUT/*.bed | wc -l)
        	mkdir ${MACSDIR}/CHIP_INPUT/BigBeds
    			sbatch --array=1-$num_files --dependency=afterany:${JOB_MACS} ${FUNCTIONSDIR}/bedtobigbed_peaks.sh ${MACSDIR}/CHIP_INPUT ${MACSDIR}/CHIP_INPUT/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
		if [ $EPIC == "true" ]
    		then
          num_files=$(ls -l ${EPICDIR}/CHIP_INPUT/*.bed | wc -l)
        	mkdir ${EPICDIR}/CHIP_INPUT/BigBeds
    			sbatch --array=1-$num_files --dependency=afterany:${JOB_EPIC} ${FUNCTIONSDIR}/bedtobigbed_peaks_epic2.sh ${EPICDIR}/CHIP_INPUT ${EPICDIR}/CHIP_INPUT/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
	else
		if [ $MACS == "true" ]
    		then
          num_files=$(ls -l ${MACSDIR}/CHIP_INPUT/*.bed | wc -l)
    			mkdir ${MACSDIR}/CHIP_INPUT/BigBeds
    			sbatch --array=1-$num_files ${FUNCTIONSDIR}/bedtobigbed_peaks.sh ${MACSDIR}/CHIP_INPUT ${MACSDIR}/CHIP_INPUT/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
		if [ $EPIC == "true" ]
    		then
          num_files=$(ls -l ${EPICDIR}/CHIP_INPUT/*.bed | wc -l)
    			mkdir ${EPICDIR}/CHIP_INPUT/BigBeds
    			sbatch --array=1-$num_files ${FUNCTIONSDIR}/bedtobigbed_peaks_epic2.sh ${EPICDIR}/CHIP_INPUT ${EPICDIR}/CHIP_INPUT/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
	fi
fi

if [ -d $OUTPUT/PEAK_CALLING/MACS2/CHIP_MOCK ] || [ -d $OUTPUT/PEAK_CALLING/EPIC2/CHIP_MOCK ]
then
	if [ $PEAK_CALL == "true" ]
	then
		mkdir ${MACSDIR}/CHIP_MOCK/BigBeds
		mkdir ${EPICDIR}/CHIP_MOCK/BigBeds
		if [ $MACS == "true" ]
    		then
          num_files=$(ls -l ${MACSDIR}/CHIP_INPUT/*.bed | wc -l)

    			sbatch --array=1-$num_files --dependency=afterany:${JOB_MACS} ${FUNCTIONSDIR}/bedtobigbed_peaks.sh ${MACSDIR}/CHIP_MOCK ${MACSDIR}/CHIP_MOCK/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
		if [ $EPIC == "true" ]
    		then
          num_files=$(ls -l ${EPICDIR}/CHIP_INPUT/*.bed | wc -l)
    			sbatch --array=1-$num_files --dependency=afterany:${JOB_EPIC} ${FUNCTIONSDIR}/bedtobigbed_peaks_epic2.sh ${EPICDIR}/CHIP_MOCK ${EPICDIR}/CHIP_MOCK/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
	else
		mkdir $OUTPUT/PEAK_CALLING/MACS2/CHIP_MOCK/BigBeds
		mkdir $OUTPUT/PEAK_CALLING/EPIC2/CHIP_MOCK/BigBeds
		if [ $MACS == "true" ]
    		then
          num_files=$(ls -l ${MACSDIR}/CHIP_INPUT/*.bed | wc -l)

    			MACSDIR=$OUTPUT/PEAK_CALLING/MACS2
    			mkdir ${MACSDIR}/CHIP_MOCK/BigBeds
    			sbatch --array=1-$num_files ${FUNCTIONSDIR}/bedtobigbed_peaks.sh ${MACSDIR}/CHIP_MOCK ${MACSDIR}/CHIP_MOCK/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
		if [ $EPIC == "true" ]
    		then
          num_files=$(ls -l ${EPICDIR}/CHIP_INPUT/*.bed | wc -l)
    			EPICDIR=$OUTPUT/PEAK_CALLING/EPIC2
    			mkdir ${EPICDIR}/CHIP_MOCK/BigBeds
    			sbatch --array=1-$num_files ${FUNCTIONSDIR}/bedtobigbed_peaks_epic2.sh ${EPICDIR}/CHIP_MOCK ${EPICDIR}/CHIP_MOCK/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
	fi
fi


fi



