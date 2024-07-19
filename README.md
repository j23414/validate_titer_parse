# validate_titer_parse
Temporary repo to document validation

``` bash
nextflow run main.nf
```

Results

``` bash
N E X T F L O W  ~  version 23.04.4
Launching `main.nf` [insane_curran] DSL2 - revision: 3c2ea6628a
executor >  local (5)
[68/dd4360] process > LIST_FILES              [100%] 1 of 1 ✔
[9e/4dbe7e] process > SELECT_2024             [100%] 1 of 1 ✔
[25/06f4cb] process > GENERATE_VIDRL_COMMANDS [100%] 1 of 1 ✔
[0b/a70e04] process > GENERATE_NIID_COMMANDS  [100%] 1 of 1 ✔
[55/bf9e1e] process > GENERATE_CRICK_COMMANDS [100%] 1 of 1 ✔
File: results/files.txt, Lines: 896
File: results/files_2024.txt, Lines: 100
Run CRICK Script: results/scripts/files_2024_crick_script.sh
Run NIID Script: results/scripts/files_2024_niid_script.sh
Run VIDRL Script: results/scripts/files_2024_vidrl_script.sh
```

From fauna directory

```
# Seems to work
bash ~/github/j23414/validate_titer_parse/results/scripts/files_2024_vidrl_script.sh
bash ~/github/j23414/validate_titer_parse/results/scripts/files_2024_niid_script.sh

# Perhaps only run the non-FRA
bash ~/github/j23414/validate_titer_parse/results/scripts/files_2024_crick_script.sh
```

Grep the final counts and compare with counts in Fauna

```
grep "measurements after filtering" my_log/*.txt
```

Pull counts per source file from Fauna

```
mkdir counts

for subtype in h1n1pdm h3n2 vic; do
    for source in vidrl crick niid; do
        envdir ~/nextstrain/env.d/seasonal-flu \
          python tdb/download.py \
          -db ${source}_tdb \
          --ftype tsv \
          --subtype ${subtype} \
          --fstem ${source}_${subtype}_2024 \
          --interval inclusion_date:2024-01-01,2024-12-31

        cat data/${source}_${subtype}_2024_titers.tsv \
        | awk -F'\t' 'OFS="\t" {
            for(i=1; i<=NF; i++) {
                sub(/_[0-9]+$/, "", $i)
            }
            print $0
        }' \
        | awk -F'\t' '{print $4}' \
        | sort \
        | uniq -c \
        > counts/${subtype}_${source}_counts.tsv
        sleep 1
    done
done
```