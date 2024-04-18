#!/bin/bash
#SBATCH -p lowmem           # Partition to submit to
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu 5Gb     # Memory in MB
#SBATCH -J ChangeNames           # job name
#SBATCH -o logs/ChangeNames.%j.out    # File to which standard out will be written
#SBATCH -e logs/ChangeNames.%j.err    # File to which standard err will be written

#-------------------------------

module load R/4.2.1-foss-2020b

FUNCTIONSDIR=$1
SAMPLE_SHEET=$2
INPUTDIR=$3
OUTDIR=$4

echo -e "Functions directory is $FUNCTIONSDIR."
echo -e "Sample sheet is $SAMPLE_SHEET."
echo -e "Input directory is $INPUTDIR."
echo -e "Output directory is $OUTDIR."

Rscript $FUNCTIONSDIR/fastq_files_changing_names.R $INPUTDIR $SAMPLE_SHEET $OUTDIR
