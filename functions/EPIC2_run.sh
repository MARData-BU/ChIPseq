#!/bin/bash
#SBATCH -p long,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J runEPIC2           # job name
#SBATCH -o logs/runEPIC2.%J.out    # File to which standard out will be written
#SBATCH -e logs/runEPIC2.%J.err    # File to which standard err will be written


#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------
PROJECTINFO=$1
PEAKDIR=$2
PHANTOM_PEAK_DIR=$3
epic2_specie=$4
CHROM_SIZES=$5
FUNCTIONSDIR=$6


number_of_comparisons=$(cat ${PROJECTINFO}/comparisons.txt | wc -l)

sbatch --array=1-$number_of_comparisons ${FUNCTIONSDIR}/EPIC2.sh ${PROJECTINFO} ${PEAKDIR} $PHANTOM_PEAK_DIR $epic2_specie $CHROM_SIZES ${FUNCTIONSDIR}



