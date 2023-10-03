#!/bin/bash
#SBATCH -p long,short,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J MV_bam           # job name
#SBATCH -o logs/MV_bam.%A_%A.out    # File to which standard out will be written
#SBATCH -e logs/MV_bam.%A_%A.err    # File to which standard err will be written


# Move bam files in order to be able to perform peak calling step

#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------


BAMDIR=$1

#-------------------------------------------------------------- Move --------------------------------------------------------------


mkdir $BAMDIR/MOCK
mkdir $BAMDIR/INPUT
mkdir $BAMDIR/CHIP

if [ $BAMDIR/*mock_sorted.dedup.filtered.bam ] 
then
	#mv $BAMDIR/*_mock_sorted.bam $BAMDIR/MOCK/
	#mv $BAMDIR/*_mock_sorted.bam.bai $BAMDIR/MOCK/
	#mv $BAMDIR/*_mock.sam $BAMDIR/MOCK/
	mv $BAMDIR/*mock_sorted.dedup.filtered.bam $BAMDIR/MOCK/
fi

#mv $BAMDIR/*_input_sorted.bam $BAMDIR/INPUT/
#mv $BAMDIR/*_input_sorted.bam.bai $BAMDIR/INPUT/
#mv $BAMDIR/*_input.sam $BAMDIR/INPUT/
mv $BAMDIR/*input_sorted.dedup.filtered.bam $BAMDIR/INPUT/

#mv $BAMDIR/*_chip_sorted.bam $BAMDIR/CHIP/
#mv $BAMDIR/*_chip_sorted.bai $BAMDIR/CHIP/
#mv $BAMDIR/*_chip.sam $BAMDIR/CHIP/
mv $BAMDIR/*chip_sorted.dedup.filtered.bam $BAMDIR/CHIP/

rm ${BAMDIR}/*.bam
rm ${BAMDIR}/*.sam
