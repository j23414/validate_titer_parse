# validate_titer_parse
Temporary repo to document validation

``` bash
nextflow run main.nf -resume
```

Results

``` bash
N E X T F L O W  ~  version 23.04.4
Launching `main.nf` [nostalgic_jones] DSL2 - revision: 991518c430
[b9/8ee6d9] process > LIST_FILES                [100%] 1 of 1, cached: 1 ✔
[0e/9d57a9] process > GENERATE_VIDRL_COMMANDS   [100%] 1 of 1, cached: 1 ✔
[9b/28999e] process > GENERATE_NIID_COMMANDS    [100%] 1 of 1, cached: 1 ✔
[8f/2bc7db] process > GENERATE_CRICK_COMMANDS   [100%] 1 of 1, cached: 1 ✔
[07/9b4a14] process > RUN_GENERATED_SCRIPTS (1) [100%] 1 of 1, cached: 1 ✔
[99/4931ec] process > FETCH_FAUNA_COUNTS        [100%] 1 of 1, cached: 1 ✔
[23/7c2c78] process > COMPARE_COUNTS (1)        [100%] 1 of 1, cached: 1 ✔
File: results/files.txt, Lines: 896
File: results/files.txt, Lines: 896
Run NIID Script: results/scripts/files_niid_script.sh
Run VIDRL Script: results/scripts/files_vidrl_script.sh
Run CRICK Script: results/scripts/files_crick_script.sh
Comparing results: results/[results_vidrl.txt, flagged_vidrl.txt]
```

<!--
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
export source=vidrl

echo "source|fauna_count" | tr '|' '\t' > ${source}_fauna.txt
cat counts/*${source}* | grep -v "source" >> ${source}_fauna.txt

echo "source|auto_count" | tr '|' '\t' > ${source}_auto.txt
grep "measurements after filtering" my_log/*.txt \
 | grep ${source} \
 |sed 's/my_log\///g' \
 | awk '{print $1}'  \
 |sed 's/.txt:/|/g'\
 | tr '|' '\t'  \
 >> ${source}_auto.txt

tsv-join -H --filter-file ${source}_auto.txt --key-fields source --append-fields auto_count --write-all '?' ${source}_fauna.txt > results_${source}.txt

```
-->

## Check results for vidrl

```
# Pull out any discrepencies in the counts
tsv-filter -H --ff-str-ne fauna_count:auto_count results/results_vidrl.txt | grep -e "2024" -e "source"
#> source	fauna_count	auto_count
```

Which means no discrepencies for 2024 data

```
# Pull out any discrepencies in the counts
tsv-filter -H --ff-str-ne fauna_count:auto_count results/results_vidrl.txt | grep -e "2023" -e "source"
#> source	fauna_count	auto_count
#> vidrl_20230117H1N1	693	?
#> vidrl_20230124H1N1	923	?
#> vidrl_20230216H1N1	649	531
#> vidrl_20230223H1N1	924	336
#> ...
```

Need to check 2023 data...

## Check results for niid

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


## VIDRL human sera processing

```bash
nextflow run vidrl_sera_processing.nf

#> N E X T F L O W  ~  version 23.04.4
#> Launching `vidrl_sera_processing.nf` [hungry_visvesvaraya] DSL2 - revision: aefea81d38
#> executor >  local (564)
#> [b8/54570e] process > LIST_VIDRL_FILES      [100%] 1 of 1 ✔
#> [7c/9b2cb1] process > RUN_TITER_BLOCK (562) [100%] 563 of 563 ✔
#> Completed at: 16-Aug-2024 10:17:30
#> Duration    : 1m 5s
#> CPU hours   : 0.1
#> Succeeded   : 564

grep -h "HumanSerumData" results_sera/titer_block/* | head -n1 > human_sera_list.tsv
grep -h "HumanSerumData" results_sera/titer_block/* | grep -v "filename"  >> human_sera_list.tsv

head -n 10 human_sera_list.tsv
#> HumanSerumData  col_idx serum_abbrev    serum_id        serum_passage   filename
#> HumanSerumData  15      vaxpool         SH 2022 /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/HI/2023/04192023H3N2.xlsx
#> HumanSerumData  15      SHvax   Human   sera    /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/HI/2020/20200311H3.xlsx
#> HumanSerumData  20      SH2020  Human   sera    /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/HI/2020/20200617H3.xlsx
#> HumanSerumData  15      SH2020  Human   sera    /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/HI/2020/20200714H3.xlsx
#> HumanSerumData  14      SHvax2020               HUMAN   /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/FRA/2020/20200804H3FRA.xlsx
#> HumanSerumData  15      SH2020  Human   sera    /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/HI/2020/20200911H3.xlsx
#> HumanSerumData  15      SH2020  Human   sera    /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/HI/2020/20201021H3.xlsx
#> HumanSerumData  15      SH2020  Human   sera    /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/HI/2020/20201209H3N2.xlsx
#> HumanSerumData  15      SH2020  Human   sera    /Users/jchang3/nextstrain/fludata/VIDRL-Melbourne-WHO-CC/raw-data/A/H3N2/HI/2020/20201222H3N2.xlsx
```
