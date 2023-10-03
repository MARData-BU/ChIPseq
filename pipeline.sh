#!/bin/bash
#SBATCH -p short         # Partition to submit to
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
num_samples=$(grep num_samples: $PARAMS | awk '{ print$2 }')

COMPARISONS=$(grep comparisons: $PARAMS | awk '{ print$2  }')


# PARAMETERS OF THE SPECIE GENOME SIZE FOR PEAK CALLING PART:
macs2_specie=$(grep macs2_specie: $PARAMS | awk '{ print$2 }')
epic2_specie=$(grep epic2_specie: $PARAMS | awk '{ print$2 }')

# Pipeline:
MERGE=$(grep merge: $PARAMS | awk '{ print$2  }')
TRIM=$(grep trimming: $PARAMS | awk '{ print$2  }')
QC=$(grep qc: $PARAMS | awk '{ print$2  }')
ALING=$(grep alignment: $PARAMS | awk '{ print$2  }')
FILTER=$(grep filtering: $PARAMS | awk '{ print$2  }')
MRG_ALIGN="false"
QC_PEAK=$(grep qc_peaks: $PARAMS | awk '{ print$2  }')
CHANGE_NAMES=$(grep changing_names: $PARAMS | awk '{ print$2  }')
PEAK_CALL=$(grep peak_calling: $PARAMS | awk '{ print$2  }')
MV_BAMS=$(grep mv_bams: $PARAMS | awk '{print$2 }')
MACS=$(grep MACS: $PARAMS | awk '{print$2 }')
EPIC=$(grep EPIC: $PARAMS | awk '{print$2 }')
BIGBED=$(grep bigbed: $PARAMS | awk '{print$2 }')

##Printing variable values

echo -e "Reading imput variables:\n"
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

echo -e "  ###" MERGE=$MERGE
echo -e "  ###" TRIMMING=$TRIM
echo -e "  ###" QC=$QC
echo -e "  ###" ALING=$ALING
echo -e "  ###" QC_PEAK=$QC_PEAK
echo -e "  ###" PEAK_CALL=$PEAK_CALL
echo -e "  ###" MV_BAMS=$MV_BAMS
echo -e "  ###" MACS=$MACS
echo -e "  ###" EPIC=$EPIC
echo -e "  ###" BIGBED=$BIGBED

echo -e "  ###" COMPARISONS=$COMPARISONS


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

if [ $ALING == "true" ]
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

mkdir $WD
cd $WD

## Creating directories
mkdir DATA RESULTS logs
mkdir DATA/logs

#echo '#!/bin/bash' > ${WD}/DATA/merge_to_run.sh


#### 3_Concatenate raw data using R script

if [ $MERGE == "true" ]
then

    echo -e "\n\nCreating the script to concatenate the FASTQ files...\n\n"

    sbatch $FUNCTIONSDIR/create_merge_file.sh $FUNCTIONSDIR $SAMPLE_SHEET $WD/DATA

    until [ -f $WD/DATA/merge_to_run.sh ] # Wait until merge_to_run.sh created.
    do
        sleep 5 # wait 5 seconds
    done

    echo "File found"

    echo -e "\n\nMerging FASTQ files...\n\n"

    sbatch --dependency=$(squeue --noheader --format %i --name create_merge_file) $WD/DATA/merge_to_run.sh # Esto peta porque no es lo mismo esperar a que se cumpla la dependencia, que el mero hecho de que esté el archivo presente. Va a esperar a que se haga la dependencia, pero aún así, necesita
    # que el archivo esté creado: por ese motivo hemos añadido la parte del until [ -f file]

    echo -e "\n\nCompressing FASTQ files...\n\n"

    count=`ls -l $WD/DATA/*.fastq | wc -l`
    condition=$num_samples
    while [ $count != $condition ] # check whether ALL the files corresponding to every sample are created or not
    do
        sleep 5 # wait if not
        count=`ls -l $WD/DATA/*.fastq | wc -l` # check again
    done

    gzip $WD/DATA/*.fastq

    echo -e "\n\nFastQ Files compressed\n\n"
else
    echo -e "\n\nChanging fastQ Files names\n\n"
    fastq_dir=${PROJECT}/rawData
    sbatch $FUNCTIONSDIR/fastq_files_names.sh $FUNCTIONSDIR $SAMPLE_SHEET $WD/DATA $fastq_dir
fi

#### 4_Trimming:
INPUT_DATA=$WD/DATA

if [ $TRIM == "true" ]
then
    echo -e "\n\nTrimming FASTQ files...\n\n"
    mkdir $INPUT_DATA/DATA_Trimmed
    INPUT_DATA_TRIM=$INPUT_DATA/DATA_Trimmed # change the data directory for the one with trimmed data
    num_files=$(ls -l $INPUT_DATA/*.fastq.gz | wc -l)
    JOB_CUTADAPT=$(sbatch --array=1-$num_files --parsable $FUNCTIONSDIR/cutadapt.sh $INPUT_DATA $INPUT_DATA_TRIM) # --parsable means that we need to save the job_id as a variable. It is necessary in order to keep running the pipeline, because we need to finish this step in order to start the others.
    echo -e "Notice that from now on, trimmed data will be used for the analysis\n\n"
else
    echo -e "No trimming step was performed\n\n"
fi
INPUT_DATA_TRIM=$INPUT_DATA/DATA_Trimmed
#### 4_Quality Control: FASTQC and FASTQScreen

if [ -v $INPUT_DATA_TRIM ]
then
    INPUT_DATA=$INPUT_DATA_TRIM
fi


if [ $QC == "true" ]
then
    echo -e "\n\nStarting QC...\n\n"

    mkdir $OUTPUT/QC
    mkdir $OUTPUT/QC/logs

    QCDIR=$OUTPUT/QC

    if [ $TRIM == "true" ] #cambiar para que se pueda hacer sin el trim cogiendo los datos bn
    then
        num_files=$(ls -l $INPUT_DATA/*.fastq.gz | wc -l)
        echo -e "\n\nQC on trimmed data...\n\n"
        sbatch --array=1-$num_files --dependency=afterok:${JOB_CUTADAPT} $FUNCTIONSDIR/QC.sh $INPUT_DATA $QCDIR # Wait until cutadapt is done. It is not necessary --parsable because none of the following scripts required to finish the qc.
    else
        num_files=$(ls -l $INPUT_DATA/*.fastq.gz | wc -l)
        echo -e "\n\nQC on data...\n\n"
        sbatch --array=1-$num_files $FUNCTIONSDIR/QC.sh $INPUT_DATA $QCDIR # else, run it
    fi
fi

#### 5.A_Alignment (BOWTIE2)
mkdir $OUTPUT/BAM_Files
mkdir $OUTPUT/BAM_Files/logs
BAMDIR=$OUTPUT/BAM_Files

if [ $ALING == "true" ]
then
    echo -e "\n\nStarting alignment with BOWTIE2...\n\n"
    num_files=$(ls -l $INPUT_DATA/*.fastq.gz | wc -l)
    if [ $TRIM == "true" ]
    then
        echo -e "\n\nAligning trimmed data...\n\n"
        JOB_ALIGN=$(sbatch --array=1-$num_files --dependency=afterok:${JOB_CUTADAPT} --parsable ${FUNCTIONSDIR}/bowtie2.sh $INPUT_DATA $BAMDIR $INDEX_BOWTIE2 $GENOME) # Wait until cutadapt is done. It is necessary to include --parsable because the alingment is a main step that has to be finished in order to keep running.

    else
        echo -e "\n\nAligning data...\n\n"
        JOB_ALIGN=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/bowtie2.sh $INPUT_DATA $BAMDIR $INDEX_BOWTIE2 $GENOME) # else, run it. It is necessary the --parsable option for keep running
    fi
fi

if [ $FILTER == "true" ]
then
  if [ $ALING == "true" ]
  then
      JOB_FILTER_BAM=$(sbatch --array=1-$num_samples --dependency=afterok:${JOB_ALIGN} --parsable ${FUNCTIONSDIR}/bam_filtering.sh $BAMDIR)
  else
      JOB_FILTER_BAM=$(sbatch --array=1-$num_samples --parsable ${FUNCTIONSDIR}/bam_filtering.sh $BAMDIR)
  fi
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
mkdir $BAMDIR/PRESEQ
PRESEQDIR=$BAMDIR/PRESEQ
mkdir $BAMDIR/BigWig
BIGWIGDIR=$BAMDIR/BigWig
mkdir $BAMDIR/Phantompeakqualtools
PHANTOMDIR=$BAMDIR/Phantompeakqualtools

if [ $QC_PEAK == "true" ]
then
num_files=$(ls -l $INPUT_DATA/*.fastq.gz | wc -l)
  if [ $FILTER == "true" ]
    #### 6_Estimation library complexity
  then
    echo -e "\n\nStarting QC once the alignment is done...\n\n"
    echo -e "\n\nStarting PRESEQ (metrics for alignment)...\n\n"
    JOB_PRESEQ=$(sbatch --array=1-$num_files --dependency=afterok:${JOB_FILTER_BAM} --parsable ${FUNCTIONSDIR}/preseq.sh $BAMDIR $PRESEQDIR)
    # it is necessary to include dependencies and --parsable because we have to wait the bam files.

    #### 7_Create normalized BigWig files for peak visualization

    echo -e "\n\nStarting BIGWIG (creating file for peak visualization)...\n\n"
    JOB_BIGWIG=$(sbatch --array=1-$num_files --dependency=afterok:${JOB_FILTER_BAM} --parsable ${FUNCTIONSDIR}/bedtools_bigwig.sh $BAMDIR $BIGWIGDIR $FUNCTIONSDIR $CHROM_SIZES)
    # it is necessary to include dependencies and --parsable because we have to wait the bam files.

    #### 9_NSC and RSC (phantompeakqualtools)

    echo -e "\n\nStarting PHANTOM PEAK QUALTOOLS (metrics for alignment)...\n\n"
    JOB_PHANTOM=$(sbatch --array=1-$num_files --dependency=afterok:${JOB_FILTER_BAM} --parsable ${FUNCTIONSDIR}/phantompeakqualtools.sh $BAMDIR $PHANTOMDIR $FUNCTIONSDIR)
    # it is necessary to include dependencies and --parsable because we have to wait the bam files.
  else
    echo -e "\n\nStarting PRESEQ (metrics for alignment)...\n\n"
    JOB_PRESEQ=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/preseq.sh $BAMDIR $PRESEQDIR)
    # it is necessary to include dependencies and --parsable because we have to wait the bam files.

    #### 7_Create normalized BigWig files for peak visualization

    echo -e "\n\nStarting BIGWIG (creating file for peak visualization)...\n\n"
    JOB_BIGWIG=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/bedtools_bigwig.sh $BAMDIR $BIGWIGDIR $FUNCTIONSDIR)
    # it is necessary to include dependencies and --parsable because we have to wait the bam files.

    #### 9_NSC and RSC (phantompeakqualtools)

    echo -e "\n\nStarting PHANTOM PEAK QUALTOOLS (metrics for alignment)...\n\n"
    JOB_PHANTOM=$(sbatch --array=1-$num_files --parsable ${FUNCTIONSDIR}/phantompeakqualtools.sh $BAMDIR $PHANTOMDIR $FUNCTIONSDIR)
    # it is necessary to include dependencies and --parsable because we have to wait the bam files.
  fi
else
  echo -e "QC is false"
fi

#### 10.B_Move BAMFiles:
if [ $MV_BAMS == "true" ]
then
  if [ $QC_PEAK == "true" ]
      then
          echo -e "\n\nClassifying BAM files into appropiate folder (input, chip and mock)...\n\n"
          JOB_MV=$(sbatch --array=1-$num_files --dependency=afterany:${JOB_PRESEQ},${JOB_BIGWIG},${JOB_PHANTOM} --parsable ${FUNCTIONSDIR}/move_bamfiles.sh $BAMDIR)
          # it is necessary to include dependencies and --parsable because we have to wait before starting the peak calling due to the fact that we are moving the bam files depending on the type of sample
      else
          echo -e "\n\nClassifying BAM files into appropiate folder (input, chip and mock)...\n\n"
          JOB_MV=$(sbatch --array=1-$num_files  --parsable ${FUNCTIONSDIR}/move_bamfiles.sh $BAMDIR)
          # it is necessary to include dependencies and --parsable because we have to wait before starting the peak calling due to the fact that we are moving the bam files depending on the type of sample
      fi
else
  echo -e "MV BAMS is false"
fi

#=================#
#   MultiQC       #
#=================#

if [ $MV_BAMS == "true" ]
then
sbatch --dependency=afterany:${JOB_MV} ${FUNCTIONSDIR}/multiQC.sh ${OUTPUT}/QC ${OUTPUT}
else
sbatch ${FUNCTIONSDIR}/multiQC.sh ${OUTPUT}/QC ${OUTPUT}
fi

#### 10.A_Peak Calling:

if [ $PEAK_CALL == "true" ]
then
    if [ $MV_BAMS == "true" ]
    then
      JOB_COMP=$(sbatch --dependency=afterany:${JOB_MV} --parsable ${FUNCTIONSDIR}/create_comparison_txt.sh ${SAMPLE_SHEET} ${BAMDIR} ${PROJECTINFO} ${FUNCTIONSDIR})
    else
      JOB_COMP=$(sbatch --parsable ${FUNCTIONSDIR}/create_comparison_txt.sh ${SAMPLE_SHEET} ${BAMDIR} ${PROJECTINFO} ${FUNCTIONSDIR})
    fi
    if [ $MACS == "true" ]
    then
    # MACS 2
    mkdir $OUTPUT/PEAK_CALLING
    mkdir $OUTPUT/PEAK_CALLING/MACS2
    MACSDIR=$OUTPUT/PEAK_CALLING/MACS2
    mkdir ${MACSDIR}/CHIP_INPUT
    mkdir ${MACSDIR}/CHIP_MOCK
    MOCKDIR=${MACSDIR}/CHIP_MOCK
    INPUTDIR=${MACSDIR}/CHIP_INPUT
    echo -e "Running MACS2"
    JOB_MACS=$(sbatch --dependency=afterany:${JOB_COMP} --parsable ${FUNCTIONSDIR}/MACS2_run.sh ${PROJECTINFO} ${MACSDIR} ${BAMDIR}/Phantompeakqualtools $macs2_specie ${FUNCTIONSDIR})
    fi

    if [ $EPIC == "true" ]
    then
    # EPIC 2
    mkdir $OUTPUT/PEAK_CALLING/EPIC2
    EPICDIR=$OUTPUT/PEAK_CALLING/EPIC2
    mkdir ${EPICDIR}/CHIP_INPUT
    mkdir ${EPICDIR}/CHIP_MOCK
    MOCKDIR=${EPICDIR}/CHIP_MOCK
    INPUTDIR=${EPICDIR}/CHIP_INPUT
    echo -e "Running EPIC2"
    JOB_EPIC=$(sbatch --dependency=afterany:${JOB_COMP} --parsable ${FUNCTIONSDIR}/EPIC2_run.sh ${PROJECTINFO} ${EPICDIR} ${BAMDIR}/Phantompeakqualtools $epic2_specie $CHROM_SIZES ${FUNCTIONSDIR})
    fi
fi



#### 11. BIG BEDS:

if [ $BIGBED == "true" ]
then
	if [ -d $OUTPUT/PEAK_CALLING/MACS2/CHIP_INPUT ] || [ -d $OUTPUT/PEAK_CALLING/EPIC2/CHIP_INPUT ]
	then
	if [ $PEAK_CALL == "true" ]
	then
		mkdir ${MACSDIR}/CHIP_INPUT/BigBeds
		mkdir ${EPICDIR}/CHIP_INPUT/BigBeds
		if [ $MACS == "true" ]
    		then
    			sbatch --dependency=afterany:${JOB_MACS} ${FUNCTIONSDIR}/bedtobigbed_run.sh ${MACSDIR}/CHIP_INPUT ${MACSDIR}/CHIP_INPUT/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
		if [ $EPIC == "true" ]
    		then
    			sbatch --dependency=afterany:${JOB_EPIC} ${FUNCTIONSDIR}/bedtobigbed_run_epic2.sh ${EPICDIR}/CHIP_INPUT ${EPICDIR}/CHIP_INPUT/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
	else
		if [ $MACS == "true" ]
    		then
    			MACSDIR=$OUTPUT/PEAK_CALLING/MACS2
    			mkdir ${MACSDIR}/CHIP_INPUT/BigBeds
    			sbatch ${FUNCTIONSDIR}/bedtobigbed_run.sh ${MACSDIR}/CHIP_INPUT ${MACSDIR}/CHIP_INPUT/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
		if [ $EPIC == "true" ]
    		then
    			EPICDIR=$OUTPUT/PEAK_CALLING/EPIC2
    			mkdir ${EPICDIR}/CHIP_INPUT/BigBeds
    			sbatch ${FUNCTIONSDIR}/bedtobigbed_run_epic2.sh ${EPICDIR}/CHIP_INPUT ${EPICDIR}/CHIP_INPUT/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
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
    			sbatch --dependency=afterany:${JOB_MACS} ${FUNCTIONSDIR}/bedtobigbed_run.sh ${MACSDIR}/CHIP_MOCK ${MACSDIR}/CHIP_MOCK/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
		if [ $EPIC == "true" ]
    		then
    			sbatch --dependency=afterany:${JOB_EPIC} ${FUNCTIONSDIR}/bedtobigbed_run_epic2.sh ${EPICDIR}/CHIP_MOCK ${EPICDIR}/CHIP_MOCK/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
	else
		mkdir $OUTPUT/PEAK_CALLING/MACS2/CHIP_MOCK/BigBeds
		mkdir $OUTPUT/PEAK_CALLING/EPIC2/CHIP_MOCK/BigBeds
		if [ $MACS == "true" ]
    		then
    			MACSDIR=$OUTPUT/PEAK_CALLING/MACS2
    			mkdir ${MACSDIR}/CHIP_MOCK/BigBeds
    			sbatch ${FUNCTIONSDIR}/bedtobigbed_run.sh ${MACSDIR}/CHIP_MOCK ${MACSDIR}/CHIP_MOCK/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
		if [ $EPIC == "true" ]
    		then
    			EPICDIR=$OUTPUT/PEAK_CALLING/EPIC2
    			mkdir ${EPICDIR}/CHIP_MOCK/BigBeds
    			sbatch ${FUNCTIONSDIR}/bedtobigbed_run_epic2.sh ${EPICDIR}/CHIP_MOCK ${EPICDIR}/CHIP_MOCK/BigBeds ${FUNCTIONSDIR} $CHROM_SIZES
    		fi
	fi
fi





fi



