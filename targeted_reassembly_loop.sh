#!/bin/bash

# Script by Rafael Laso-P�rez (https://orcid.org/0000-0002-6912-7865)

# Define working directory
wd="working_directory"

# Define input libaries directory
dir="input_libraries_directory"
# Sample forward & reverse reads
l1="1_R1_trimmed.fastq"
l2="1_R2_trimmed.fastq"
# Add additional samples if applicable

# BBMap parameters
ref="scaffolds_1500.fasta"
THREADS="15"

###################################################################################################################

cd "$wd"

mkdir 1_reassembly
cd 1_reassembly

module load bbmap-38.44/38.44

# Mapping for sample 1
bbmap.sh ref=mag.fa in="$dir""$l1" in2="$dir""$l2" nodisk minid=0.97 threads="$THREADS" outm=sample.sam # mag.fa is the target MAG to reassemble

# Convert alignment file (.sam) to fastq files for reassemby
java -jar picard.jar SamToFastq I=sample.sam F=Lib1_R1.fastq F2=Lib1_R2.fastq

# Reassembly of the mapped reads with SPAdes
module load spades/3.9.0
mkdir Assembly
spades.py -t "$THREADS" -o Assembly --pe1-1 Lib1_R1.fastq --pe1-2 Lib1_R2.fastq

mkdir Checkm
cd Checkm
ln -s ../Assembly/scaffolds.fasta
perl removesmalls.pl 1500 scaffolds.fasta > 1_"$ref" # from https://github.com/drtamermansour/p_asteroides/blob/master/scripts/removesmalls.pl

module unload spades/3.9.0 bbmap-38.44/38.44
. /opt/anaconda3/etc/profile.d/conda.sh
conda activate py27
module load checkm_b/checkm_b
module unload anaconda2/2.4.0 pplacer/1.1.alpha18 hmmer/3.1b2 # These modules otherwise interfere with CheckM

checkm lineage_wf -x fasta -t "$THREADS"  -f Output_file ./ ./Checkm_folder
checkm qa -o 2 --tab_table -f Output_file_extended ./Checkm_folder/*.ms ./Checkm_folder/
grep "_scaffolds_1500" Output_file_extended >> ../../Reassembly_stats

module unload checkm_b/checkm_b
module load spades/3.9.0 bbmap-38.44/38.44

cd ../../

for i in {2..25}
do
mkdir ${i}_reassembly
cd ${i}_reassembly
((e = $i-1))
ln -s ../${e}_reassembly/Checkm/${e}_"$ref"

# Mpping for sample 1
bbmap.sh ref=${e}_"$ref" in="$dir""$l1" in2="$dir""$l2" nodisk minid=0.98 threads="$THREADS" outm=sample.sam

# Convert alignment file (.sam) to fastq files for reassemby
java -jar picard.jar SamToFastq I=sample.sam F=Lib1_R1.fastq F2=Lib1_R2.fastq

# Reassembly of the mapped reads with SPAdes
mkdir Assembly
spades.py -t "$THREADS" -o Assembly --pe1-1 Lib1_R1.fastq --pe1-2 Lib1_R2.fastq

mkdir Checkm
cd Checkm
ln -s ../Assembly/scaffolds.fasta
perl removesmalls.pl 1500 scaffolds.fasta > ${i}_"$ref"

module unload spades/3.9.0 bbmap-38.44/38.44
. /opt/anaconda3/etc/profile.d/conda.sh
conda activate py27
module load checkm_b/checkm_b
module unload anaconda2/2.4.0 pplacer/1.1.alpha18 hmmer/3.1b2 #these modules otherwise interfere with checkm

checkm lineage_wf -x fasta -t "$THREADS"  -f Output_file ./ ./Checkm_folder
checkm qa -o 2 --tab_table -f Output_file_extended ./Checkm_folder/*.ms ./Checkm_folder/
grep "_scaffolds_1500" Output_file_extended >> ../../Reassembly_stats

module unload checkm_b/checkm_b
module load spades/3.9.0 bbmap-38.44/38.44

cd ../../
done

cd "$wd"
