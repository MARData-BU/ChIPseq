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

# We will create hyperlinks so files do not need to be moved, which takes longer time

find "$BAMDIR" -maxdepth 1 -type f -name '*mock_sorted.dedup.filtered.bam' | while read -r file; do
	echo "$file"
	ln -sf "$file" "$BAMDIR/MOCK/"
done

find "$BAMDIR" -maxdepth 1 -type f -name '*input_sorted.dedup.filtered.bam' | while read -r file; do
	echo "$file"
	ln -sf "$file" "$BAMDIR/INPUT/"
done

find "$BAMDIR" -maxdepth 1 -type f -name '*chip_sorted.dedup.filtered.bam' | while read -r file; do
	echo "$file"
	ln -sf "$file" "$BAMDIR/CHIP/"
done
