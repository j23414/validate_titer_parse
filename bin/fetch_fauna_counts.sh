#! /usr/bin/env bash

set -euv

mkdir counts

for subtype in h1n1pdm h3n2 vic; do
    for source in vidrl crick niid; do
        envdir ~/nextstrain/env.d/seasonal-flu \
         python tdb/download.py \
         -db ${source}_tdb \
         --ftype tsv \
         --subtype ${subtype} \
         --fstem ${source}_${subtype}_all \
         #--fstem ${source}_${subtype}_2024 \
         #--interval inclusion_date:2024-01-01,2024-12-31

        cat data/${source}_${subtype}_all_titers.tsv \
        | awk -F'\t' 'OFS="\t" {
            for(i=1; i<=NF; i++) {
                sub(/_[0-9]+$/, "", $i)
            }
            print $0
        }' \
        | awk -F'\t' '{print $4}' \
        | awk -F'.' '{print $1}' \
        | sort \
        | uniq -c \
        | awk 'OFS="\t" {print $2,$1}' \
        > counts/${subtype}_${source}_counts.tsv
        sleep 1
    done
done