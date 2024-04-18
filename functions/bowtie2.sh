#!/bin/bash
#SBATCH -p bigmem            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 50Gb     # Memory in MB
#SBATCH -J Bowtie2           # job name
#SBATCH -o logs/Bowtie2.%j.out    # File to which standard out will be written
#SBATCH -e logs/Bowtie2.%j.err    # File to which standard err will be written

##Ari 16/01/2023: BOWTIE2 ALIGNMENT

#======MODULES======#
module purge
module load SAMtools/1.12-GCC-10.2.0
module load Bowtie2/2.4.2-GCC-10.2.0
module load picard/2.25.1-Java-11
module load R/4.2.2

echo -e "Modules loaded."
#======NEEDED FILES======#

FASTQDIR=$1
OUTDIR=$2
INDEX_BOWTIE2=$3
ANNOTGENE=$4

mkdir $OUTDIR/Picard
PICARDIR=$OUTDIR/Picard

#======LOOP======#

FASTQFILES=($(ls -1 $FASTQDIR/*.fastq.gz))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISFASTQFILE=${FASTQFILES[$i]}

name=$(basename ${THISFASTQFILE} .fastq.gz)

echo -e "Running BOWTIE2 and Picard for sample $name."

##==================#
#  BOWTIE2 + Picard #
##==================#

echo $THISFASTQFILE
bowtie2 -x $INDEX_BOWTIE2 -U ${THISFASTQFILE} -S ${OUTDIR}/${name}.sam
samtools sort -o ${OUTDIR}/${name}_sorted.bam ${OUTDIR}/${name}.sam
samtools index ${OUTDIR}/${name}_sorted.bam
samtools stats ${OUTDIR}/${name}_sorted.bam
java -jar $EBROOTPICARD/picard.jar CollectMultipleMetrics \
  -I ${OUTDIR}/${name}_sorted.bam \
  -O ${PICARDIR}/${name}.Multiple_Metrics \
  -R ${ANNOTGENE}

echo "Java and alignment are already done"
