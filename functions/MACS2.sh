#!/bin/bash
#SBATCH -p long,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J MACS2           # job name
#SBATCH -o logs/MACS2.%A_%a.out    # File to which standard out will be written
#SBATCH -e logs/MACS2.%A_%a.err    # File to which standard err will be written


#-------------------------------------------------------------- MODULES --------------------------------------------------------------
module purge
module load Python/3.8.6-GCCcore-10.2.0



#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------
PROJECTINFO=$1
PEAKDIR=$2
PHANTOM_PEAK_DIR=$3
macs2_specie=$4
FUNCTIONSDIR=$5

i=$(($SLURM_ARRAY_TASK_ID))

#CHIP_FILE=$(ls -l ${CHIP_DIR}/*${THISCOMP}_chip_sorted.bam)
CHIP_FILE=$(cat ${PROJECTINFO}/comparisons.txt | awk 'NR=='$i' {print $1}')
CONTROL_FILE=$(cat ${PROJECTINFO}/comparisons.txt | awk 'NR=='$i' {print $2}')

echo $CHIP_FILE
echo $CONTROL_FILE

#Get the info from phantompeakqualtools
temp_var=$(echo $CHIP_FILE | rev | cut -d '/' -f 1 | rev)
echo $temp_var
PHANTOM_PEAK=$(cat ${PHANTOM_PEAK_DIR}/${temp_var}.spp.out | cut -f 3 | cut -d "," -f 1  )
#-------------------------------------------------------------- COMMAND --------------------------------------------------------------

if echo "$CONTROL_FILE" | grep -q "mock"; then
THISCOMP=$(basename $CHIP_FILE "_mock_sorted.dedup.filtered.bam")
macs2 callpeak -t $CHIP_FILE -c $CONTROL_FILE -n ${THISCOMP}_chip_vs_mock --nomodel --extsize $PHANTOM_PEAK --outdir ${PEAKDIR}/CHIP_MOCK -f BAM -g $macs2_specie
echo "${THISCOMP}_chip_vs_mock" done! >> ${PEAKDIR}/CHIP_MOCK/count.txt
else
THISCOMP=$(basename $CHIP_FILE "_input_sorted.dedup.filtered.bam")
macs2 callpeak -t $CHIP_FILE -c $CONTROL_FILE -n ${THISCOMP}_chip_vs_input --nomodel --extsize $PHANTOM_PEAK --outdir ${PEAKDIR}/CHIP_INPUT -f BAM -g $macs2_specie
echo "${THISCOMP}_chip_vs_input" done! >> ${PEAKDIR}/CHIP_INPUT/count.txt
fi


