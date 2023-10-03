#!/bin/bash
#SBATCH -p lowmem           # Partition to submit to
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu 5Gb     # Memory in MB
#SBATCH -J TrimCutadapt           # job name
#SBATCH -o logs/TrimCutadapt.%j.out    # File to which standard out will be written
#SBATCH -e logs/TrimCutadapt.%j.err    # File to which standard err will be written

#-------------------------------

module load R/4.2.1-foss-2020b


FUNCTIONSDIR=$1
SAMPLE_SHEET=$2
OUTDIR=$3
INPUTDIR=$4

Rscript $FUNCTIONSDIR/fastq_files_changing_names.R $INPUTDIR $sample_sheet $OUTDIR
