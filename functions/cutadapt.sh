#!/bin/bash
#SBATCH -p lowmem           # Partition to submit to
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu 5Gb     # Memory in MB
#SBATCH -J TrimCutadapt           # job name
#SBATCH -o logs/TrimCutadapt.%j.out    # File to which standard out will be written
#SBATCH -e logs/TrimCutadapt.%j.err    # File to which standard err will be written

#-------------------------------

module purge  ## Why? Clear out .bashrc /.bash_profile settings that might interfere
module load Python/3.8.6-GCCcore-10.2.0

#create logs folder:
mkdir ./logs
#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------

FASTQDIR=$1
OUTDIR=$2

#--------------------

FASTQFILES=($(ls -1 $FASTQDIR/*.fastq.gz))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISFASTQFILE=${FASTQFILES[i]}

name=$(basename ${THISFASTQFILE})

cutadapt -m 20 -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC -o ${OUTDIR}/${name} ${THISFASTQFILE} #adapter seq from https://github.com/vsbuffalo/scythe/blob/master/illumina_adapters.fa
#echo "testing cutadapt script for using trimmed data"
