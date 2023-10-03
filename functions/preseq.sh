#!/bin/bash
#SBATCH -p bigmem            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 20Gb     # Memory in MB
#SBATCH -J preseq           # job name
#SBATCH -o logs/preseq.%A_%a.out    # File to which standard out will be written
#SBATCH -e logs/preseq.%A_%a.err    # File to which standard err will be written

#-------------------------------------------------------------- MODULES --------------------------------------------------------------
module purge
module load preseq/3.2.0
module load BEDTools/2.30.0-GCC-10.2.0

#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------

BAMDIR=$1
PRESEQDIR=$2
mkdir ${PRESEQDIR}/BEDFiles
#-------------------------------------------------------------- LOOP --------------------------------------------------------------
BAMFILES=($(ls -1 $BAMDIR/*.dedup.filtered.bam))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISBAMFILE=${BAMFILES[i]}

name=$(basename ${THISBAMFILE})

bedtools bamtobed -i $THISBAMFILE > ${PRESEQDIR}/BEDFiles/${name}.bed

/soft/system/software/preseq/3.2.0/preseq lc_extrap -o ${PRESEQDIR}/${name}_lc_extrap.txt ${PRESEQDIR}/BEDFiles/${name}.bed # predict the complexity curve of a sequencing library
