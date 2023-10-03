#!/bin/bash
#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J COMPARISONS           # job name
#SBATCH -o logs/COMPARISONS.%J.out    # File to which standard out will be written
#SBATCH -e logs/COMPARISONS.%J.err    # File to which standard err will be written

module purge
module load R/4.2.1-foss-2020b


SAMPLE_SHEET=$1
BAMDIR=$2
PROJECTINFO=$3
FUNCTIONSDIR=$4

Rscript ${FUNCTIONSDIR}/create_comparison_txt.R $SAMPLE_SHEET $BAMDIR $PROJECTINFO
