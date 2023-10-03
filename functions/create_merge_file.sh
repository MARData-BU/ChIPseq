#!/bin/bash
#SBATCH -p long,short,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J create_merge_file           # job name
#SBATCH -o logs/runR.%J.out    # File to which standard out will be written
#SBATCH -e logs/runR.%J.err    # File to which standard err will be written

module load R/4.2.1-foss-2020b
FUNCTIONSDIR=$1
sample_sheet=$2
DATA=$3
Rscript $FUNCTIONSDIR/Merge_Files.R $sample_sheet $DATA
