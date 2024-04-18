#!/bin/bash
#SBATCH -p long           # Partition to submit to
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu 20Gb     # Memory in MB
#SBATCH -J phantompeak           # job name
#SBATCH -o logs/phantompeak.%j.out    # File to which standard out will be written
#SBATCH -e logs/phantompeak.%j.err    # File to which standard err will be written

#-------------------------------

module purge  ## Why? Clear out .bashrc /.bash_profile settings that might interfere
module load R/4.2.2
module load SAMtools/1.12-GCC-10.2.0

#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------

BAMDIR=$1
OUTPUT=$2
FUNCTIONSDIR=$3

BAMFILES=($(ls -1 $BAMDIR/*.dedup.filtered.bam))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISBAMFILE=${BAMFILES[i]}

name=$(basename ${THISBAMFILE})


#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------


Rscript ${FUNCTIONSDIR}/run_spp.R -c=$THISBAMFILE -savp="${OUTPUT}/${name}.spp.pdf" -savd="${OUTPUT}/${name}.spp.RData" -out="${OUTPUT}/${name}.spp.out"

