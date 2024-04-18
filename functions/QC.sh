#!/bin/bash
#SBATCH -p long,short,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J QC           # job name
#SBATCH -o logs/QC.%j.out    # File to which standard out will be written
#SBATCH -e logs/QC.%j.err    # File to which standard err will be written

#-------------------------------

#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------

FASTQDIR=$1
OUTDIR=$2
config=/bicoh/MARGenomics/AnalysisFiles/Index_Genomes_Bowtie2/fastq_screen.conf

### CREATE OUTDIR FOLDERS:
mkdir ${OUTDIR}/FastqScreen
mkdir ${OUTDIR}/FastQC

OUTDIR_fastqscreen=${OUTDIR}/FastqScreen
OUTDIR_fastqc=${OUTDIR}/FastQC

FASTQFILES=($(ls -1 $FASTQDIR/*.fastq.gz))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISFASTQFILE=${FASTQFILES[i]}


#-------------------------------#
#---------FASTQ SCREEN----------#
#-------------------------------#

module purge  ## Why? Clear out .bashrc /.bash_profile settings that might interfere
module load FastQ-Screen/0.14.1
module load Bowtie2/2.4.2-GCC-10.2.0		# Required for Fastqscreen



fastq_screen --threads $SLURM_CPUS_PER_TASK --conf $config --outdir ${OUTDIR_fastqscreen} $THISFASTQFILE


#--------------------------------#
#-------------FASTQC ------------#
#--------------------------------#

module purge 
module load FastQC/0.11.7-Java-1.8.0_162       

fastqc --outdir ${OUTDIR_fastqc} --threads $SLURM_CPUS_PER_TASK $THISFASTQFILE

