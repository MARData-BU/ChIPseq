#!/bin/bash
#SBATCH -p bigmem            # Partition to submit to
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu 30Gb     # Memory in MB
#SBATCH -J BIGWIG           # job name
#SBATCH -o logs/BIGWIG.%A_%a.out    # File to which standard out will be written
#SBATCH -e logs/BIGWIG.%A_%a.err    # File to which standard err will be written


#-------------------------------------------------------------- MODULES --------------------------------------------------------------
module purge
module load BEDTools/2.30.0-GCC-10.2.0
module load SAMtools/1.12-GCC-10.2.0
#-------------------------------------------------------------- NEEDED FILES AND PATHS --------------------------------------------------------------

BAMDIR=$1
BIGWIGDIR=$2
FUNCTIONDIR=$3
chrom_sizes=$4
# we need a file of chromosome sizes for the bedGraphToBigWig program: it is created using fasta file; see below

#-------------------------------------------------------------- LOOP --------------------------------------------------------------
BAMFILES=($(ls -1 $BAMDIR/*dedup.filtered.bam))

i=$(($SLURM_ARRAY_TASK_ID - 1))

THISBAMFILE=${BAMFILES[i]}

name=$(basename ${THISBAMFILE} .bam)

#-------------------------------------------------------------- COMMAND --------------------------------------------------------------

bedtools genomecov -ibam $THISBAMFILE -bg -scale 1 > ${BIGWIGDIR}/${name}.bedgraph #scale 1 option: scale our coverage to reads/million instead of the command above, use the scaling option to scale it to the total number of mapped reads in millions replace the 1 in "-scale 1" with however many million reads are in your file


# it is necesary to have the bedgraph sorted:
# cut -f 1,2 genome.fa.fai > chrom.sizes in order to get the chrom.sizes for the fasta that you used in the analysis. In this case we are using: /bicoh/MARGenomics/Ref_Genomes_fa/GRCh38/GRCh38.primary_assembly.genome.fa.fai

#cut -f 1,2 /bicoh/MARGenomics/Ref_Genomes_fa/GRCh38/GRCh38.primary_assembly.genome.fa.fai > ${FUNCTIONDIR}/GRCh38.primary_assembly.genome.chrom.sizes

LC_COLLATE=C sort -k1,1 -k2,2n ${BIGWIGDIR}/${name}.bedgraph > ${BIGWIGDIR}/${name}.sorted.bedgraph

${FUNCTIONDIR}/bedGraphToBigWig ${BIGWIGDIR}/${name}.sorted.bedgraph $chrom_sizes ${BIGWIGDIR}/${name}.bw

### Getting the number of mapped reads ###

samtools idxstats ${THISBAMFILE} | awk '{sum+=$3}END{print sum}'
