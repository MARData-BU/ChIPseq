#!/bin/bash
#SBATCH -p short,normal,long           # Partition to submit to
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 20Gb     # Memory in MB
#SBATCH -J gzip           # job name
#SBATCH -o logs/gzip.%j.out    # File to which standard out will be written
#SBATCH -e logs/gzip.%j.err    # File to which standard err will be written

FASTQDIR=$1
FASTQFILES=($(ls -1 $FASTQDIR/*.fastq))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISFASTQFILE=${FASTQFILES[i]}
name=$(basename ${THISFASTQFILE})

echo -e "\n\nCompressing $name\n\n"

gzip $THISFASTQFILE


