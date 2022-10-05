#!/bin/bash -l

#### Cytochrome C analysis - CxxCH motif scan ####
# Script originally by Viola Krukenberg & modified by Rafael Laso-Pérez

# Define working directory
wd="working_directory"

# Define directory where annotated genome (.faa) is located
genomeDir="genome_directory"

# Name of the genome (the .faa file without ending)
Genome="genome_name"

# Motif to search for
motif="C[A-Z][A-Z]CH"

# Short name of the motif
motifName="CXXCH"

#################################################

cd "$wd"

mkdir "$motifName"_scan

cp "$genomeDir""$Genome".faa "$motifName"_scan

cd "$motifName"_scan

# Modify annotated .faa file
awk  '{ if ($1 ~ /^>/) { printf("\n%s\n", $0) } else { printf("%s", $0) }}' "$Genome".faa > modified_"$Genome".faa

# Find sequences containing the motif and output them to new file
grep -B 1 "$motif" modified_"$Genome".faa > "$motif"_motif_"$Genome".faa

# Make a list with header (including annotation) of the sequences containing the motif
grep '^>' "$motif"_motif_"$Genome".faa | sed 's/^>//' > motifList_"$Genome".txt

# Make a list of only IDs of the motif containing sequences
grep '^>' "$motif"_motif_"$Genome".faa | sed 's/>//' | sed 's/ .*//' > motifIds_"$Genome".txt

# This extracts sequences using a list of IDs
grep -A 1 -f motifIds_"$Genome".txt modified_"$Genome".faa > Sequences_"$motifName"motif_"$Genome".fasta

# Make directory for count data
mkdir motifCountTables_"$motifName"

# Copy the file containing the sequences to the new directory
cp Sequences_"$motifName"motif_"$Genome".fasta motifCountTables_"$motifName"

cd  motifCountTables_"$motifName"

# Split the multifasta file into separate files each containing one sequence
csplit -f "$motifName" Sequences_"$motifName"motif_"$Genome".fasta '/>/' '{*}'

# For each fasta file from csplit output make a file with the ORF name, count the number of motifs
for File in "$motifName"*

do

echo "$File"

grep '>' "$File" | sed 's/^>//' > "$File"_name

# Grep every motif (-o for only matching patterns) and make a list with all motifs founds
grep -o "$motif" "$File" >  "$File"_list

# Count the number of lines in the list of motifs found to know the number of motifs in the sequence
wc -l "$File"_list > "$File"_count

# Make a table with the number of motifs and the ORF name, separate the columns by a tab
paste "$File"_count  "$File"_name   | column -c columns -s $'\t' > CountTable_"$File".tab

done

# Concatinate the tables created for each file into one big table
cat CountTable*.tab > CountTableAll_"$motifName".tab

# Remove the first line (contains no data), then remove file name after count (separated by a space) and add a header to the columns of the table
tail -n +2 CountTableAll_"$motifName".tab | sed 's/ .*\t/\t/' | sed '1i\motif#\tORF' > FinalCountTableAll_"$motifName".tab

# Clean the directory by moving the in previous steps generated files to separate folders
mkdir Names
mv *_name Names/

mkdir Lists
mv *_list Lists/

mkdir Counts
mv *_count Counts/

mkdir CountTables
mv CountTable_* CountTables/

mkdir SequFiles
mv "$motifName"* SequFiles/
