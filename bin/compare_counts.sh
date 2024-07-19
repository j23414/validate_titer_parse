#! /usr/bin/env bash
# Expected files or directories
# fauna_counts/ - directory containing files with the format "*<source>*.txt"
# my_log/       - directory containing log files with the format "*.txt"

# vidrl, niid, or crick
export source=$1

echo "source|fauna_count" | tr '|' '\t' > ${source}_fauna.txt
cat *${source}_counts.tsv | grep -v "source" >> ${source}_fauna.txt

echo "source|auto_count" | tr '|' '\t' > ${source}_auto.txt
grep "measurements after filtering" ${source}_*.txt \
 | grep ${source} \
 |sed 's/my_log\///g' \
 | awk '{print $1}'  \
 |sed 's/.txt:/|/g'\
 | tr '|' '\t'  \
 >> ${source}_auto.txt

tsv-join -H --filter-file ${source}_auto.txt --key-fields source --append-fields auto_count --write-all '?' ${source}_fauna.txt > results_${source}.txt

# Pull out any discrepencies in the counts
tsv-filter -H --ff-str-ne fauna_count:auto_count results_${source}.txt > flagged_${source}.txt