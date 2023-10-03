#!/bin/bash
#SBATCH -p long,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J EPIC2           # job name
#SBATCH -o logs/EPIC2.%A_%a.out    # File to which standard out will be written
#SBATCH -e logs/EPIC2.%A_%a.err    # File to which standard err will be written


#-------------------------------------------------------------- MODULES --------------------------------------------------------------
module purge
module load Miniconda3

#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------
PROJECTINFO=$1
PEAKDIR=$2
PHANTOM_PEAK_DIR=$3
epic2_specie=$4
CHROM_SIZES=$5
FUNCTIONSDIR=$6



i=$(($SLURM_ARRAY_TASK_ID))

#CHIP_FILE=$(ls -l ${CHIP_DIR}/*${THISCOMP}_chip_sorted.bam)
CHIP_FILE=$(cat ${PROJECTINFO}/comparisons.txt | awk 'NR=='$i' {print $1}')
CONTROL_FILE=$(cat ${PROJECTINFO}/comparisons.txt | awk 'NR=='$i' {print $2}')

echo $CHIP_FILE
echo $CONTROL_FILE
echo $CHROM_SIZES

#Get the info from phantompeakqualtools
temp_var=$(echo $CHIP_FILE | rev | cut -d '/' -f 1 | rev)
echo $temp_var
PHANTOM_PEAK=$(cat ${PHANTOM_PEAK_DIR}/${temp_var}.spp.out | cut -f 3 | cut -d "," -f 1  )

#-------------------------------------------------------------- COMMAND --------------------------------------------------------------

if echo "$CONTROL_FILE" | grep -q "mock"; then
THISCOMP=$(basename $CHIP_FILE "_mock_sorted.dedup.filtered.bam")
epic2 --treatment $CHIP_FILE \
    --control $CONTROL_FILE \
    --genome $epic2_specie \
    --chromsizes $CHROM_SIZES \
    --fragment-size $PHANTOM_PEAK \
    --false-discovery-rate-cutoff 0.05 \
    --output ${PEAKDIR}/CHIP_MOCK/${THISCOMP}_chip_vs_mock_epic2.txt
echo "${THISCOMP}_chip_vs_mock" done! >> ${PEAKDIR}/CHIP_MOCK/count.txt
else
THISCOMP=$(basename $CHIP_FILE "_input_sorted.dedup.filtered.bam")
epic2 --treatment $CHIP_FILE \
    --control $CONTROL_FILE \
    --genome $epic2_specie \
    --chromsizes $CHROM_SIZES \
    --fragment-size $PHANTOM_PEAK \
    --false-discovery-rate-cutoff 0.05 \
    --output ${PEAKDIR}/CHIP_INPUT/${THISCOMP}_chip_vs_input_epic2.txt
    echo "${THISCOMP}_chip_vs_input" done! >> ${PEAKDIR}/CHIP_INPUT/count.txt
fi