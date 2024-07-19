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

Run locally by linking required directories from the Fauna directory

```
ln -s ~/nextstrain/fauna/tdb .
ln -s ~/nextstrain/fauna/source-data .
mkdir -p data/tmp
conda activate fauna
export PYTHONPATH="/Users/jchang3/nextstrain/fauna:$PYTHONPATH"

# Create a log directory to store logs for each file
mkdir my_logs
```

```
# Seems to work
bash results/scripts/files_2024_vidrl_script.sh
bash results/scripts/files_2024_niid_script.sh

# Perhaps only run the non-FRA, fix the output file names
mkdir -p ../fludata/Crick-London-WHO-CC/processed-data/tsv/
bash ~/github/j23414/validate_titer_parse/results/scripts/files_2024_crick_script.sh
```

Grep the final counts and compare with counts in Fauna

```
grep "measurements after filtering" my_log/*.txt | less
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
        | awk -F'.' '{print $1}' \
        | sort \
        | uniq -c \
        | awk 'OFS="\t" {print $2,$1}' \
        > counts/${subtype}_${source}_counts.tsv
        sleep 1
    done
done
```

Compare

```
echo "source|fauna_count" | tr '|' '\t' > vidrl_fauna.txt
cat counts/*vidrl* | grep -v "source" >> vidrl_fauna.txt
echo "source|auto_count" | tr '|' '\t' > vidrl_auto.txt
grep "measurements after filtering" my_log/*.txt | grep vidrl |sed 's/my_log\///g' | awk '{print $1}'  |sed 's/.txt:/|/g'| tr '|' '\t'  >> vidrl_auto.txt
tsv-join -H --filter-file vidrl_auto.txt --key-fields source --append-fields auto_count --write-all '?' vidrl_fauna.txt > results_vidrl.txt

# Pull out any discrepencies in the counts
tsv-filter -H --ff-str-ne fauna_count:auto_count results_vidrl.txt
#> source	fauna_count	auto_count
#> vidrl_20231220H3N2	768	?
```

```
echo "source|fauna_count" | tr '|' '\t' > niid_fauna.txt
cat counts/*niid* | grep -v "source" >> niid_fauna.txt
echo "source|auto_count" | tr '|' '\t' > niid_auto.txt
grep "measurements after filtering" my_log/*.txt | grep niid |sed 's/my_log\///g' | awk '{print $1}'  |sed 's/.txt:/|/g'| tr '|' '\t'  >> niid_auto.txt
tsv-join -H --filter-file niid_auto.txt --key-fields source --append-fields auto_count --write-all '?' niid_fauna.txt > results_niid.txt

# Pull out any discrepencies in the counts
tsv-filter -H --ff-str-ne fauna_count:auto_count results_niid.txt
#> source	fauna_count	auto_count
#> niid_H3_HIdata(20240516)	168	160
#> niid_H3_HIdata(20240704)	180	?
```

For the first one: Opening the file revealed that there is an empty line before the last row (8 measurements), violating two consecutive cells in the vertical direction. However there are consecutive cells in the horizontal direction.
However this discrepency would be flagged by the manual check of the upload process.

For the second one, still investigating.

```
  File "tdb/titer_block.py", line 262, in find_serum_rows
    cell_value = str(worksheet.cell_value(serum_abbrev_row_idx, col_idx))
TypeError: list indices must be integers or slices, not NoneType
```
