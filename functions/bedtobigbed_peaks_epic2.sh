#!/bin/bash
#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu 2Gb     # Memory in MB
#SBATCH -J BigBed           # job name
#SBATCH -o logs/BigBed.%A_%a.out    # File to which standard out will be written
#SBATCH -e logs/BigBed.%A_%a.err    # File to which standard err will be written


#-------------------------------------------------------------- MODULES --------------------------------------------------------------
module purge
module load BEDTools/2.30.0-GCC-10.2.0
#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------

PEAKDIR=$1
BIGBEDDIR=$2
FUNCTIONDIR=$3
CHROM_SIZE=$4
# we need a file of chromosome sizes for the BigBed program: it is created using fasta file; see below

#-------------------------------------------------------------- LOOP --------------------------------------------------------------
BEDFILES=($(ls -1 ${PEAKDIR}/*epic2.txt))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISBEDFILE=${BEDFILES[i]}

echo $THISBEDFILE
echo ${PEAKDIR}/${name}

name=$(basename $THISBEDFILE .txt)

cut -f 1,2,3,4,9 $THISBEDFILE > ${PEAKDIR}/${name}.bed

#-------------------------------------------------------------- COMMAND --------------------------------------------------------------

bedtools sort -i ${PEAKDIR}/${name}.bed > ${PEAKDIR}/${name}.sorted.bed

# this step is necessary because bedtobigbed does not allow to have floats!!! : 
awk -F '\t' '{OFS="\t"; $5=""; print}' ${PEAKDIR}/${name}.sorted.bed > ${PEAKDIR}/${name}.sorted.filtered.bed


${FUNCTIONDIR}/bedClip ${PEAKDIR}/${name}.sorted.filtered.bed ${CHROM_SIZE} ${PEAKDIR}/${name}.sorted.filtered.checked.bed


${FUNCTIONDIR}/bedToBigBed ${PEAKDIR}/${name}.sorted.filtered.checked.bed ${CHROM_SIZE} ${BIGBEDDIR}/${name}.sorted.filtered.checked.bb


