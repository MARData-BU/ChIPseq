#!/bin/bash
#SBATCH -p long,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J runMACS2           # job name
#SBATCH -o logs/runMACS2.%J.out    # File to which standard out will be written
#SBATCH -e logs/runMACS2.%J.err    # File to which standard err will be written


#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------
PROJECTINFO=$1
PEAKDIR=$2
PHANTOM_PEAK_DIR=$3
macs2_specie=$4
FUNCTIONSDIR=$5

number_of_comparisons=$(cat ${PROJECTINFO}/comparisons.txt | wc -l)

sbatch --array=1-$number_of_comparisons ${FUNCTIONSDIR}/MACS2.sh ${PROJECTINFO} ${PEAKDIR} $PHANTOM_PEAK_DIR $macs2_specie ${FUNCTIONSDIR}


