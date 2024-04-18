#!/bin/bash
#SBATCH -p long,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J BAMFiltering           # job name
#SBATCH -o logs/BAMFiltering.%A_%a.out    # File to which standard out will be written
#SBATCH -e logs/BAMFiltering.%A_%a.err    # File to which standard err will be written


#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------
module purge
module load picard/2.25.1-Java-11
module load SAMtools/1.12-GCC-10.2.0


# Inputs
DIR=$1

echo -e "The BAM directory has been defined as $DIR."

#-------------------------------------------------------------- LOOP --------------------------------------------------------------

BAMFILES=($(ls -1 $DIR/*_sorted.bam))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISBAMFILE=${BAMFILES[i]}

name=$(basename ${THISBAMFILE} .bam)

echo -e "Analyzing BAM $name."

#-------------------------------------------------------------- COMMAND --------------------------------------------------------------

java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
I=$THISBAMFILE \
O=${DIR}/${name}.dedup.bam \
M=${DIR}/${name}_markduplicates_Metrics.txt

samtools view -h -F 1804 -q 20 ${DIR}/${name}.dedup.bam | samtools sort -O bam -o ${DIR}/${name}.dedup.filtered.bam
