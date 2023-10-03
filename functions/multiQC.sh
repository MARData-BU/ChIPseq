#!/bin/bash
#SBATCH -p long            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 10Gb     # Memory in MB
#SBATCH -J multiqc           # job name
#SBATCH -o logs/multiqc.%j.out    # File to which standard out will be written
#SBATCH -e logs/multiqc.%j.err    # File to which standard err will be written

#======MODULES======#
module purge
module load Python/3.8.6-GCCcore-10.2.0

#======NEEDED FILES======#
QCDIR=$1
OUTPUT=$2


#======COMMAND======#

mkdir ${QCDIR}/multiQC
MULTIQCDIR=${QCDIR}/multiQC

multiqc ${OUTPUT}/* -f -o $MULTIQCDIR
