# validate_titer_parse
Temporary repo to document validation

``` bash
nextflow run main.nf
```

Results

``` bash
N E X T F L O W  ~  version 23.04.4
Launching `main.nf` [fabulous_galileo] DSL2 - revision: e3e70a9c04
executor >  local (3)
[e2/1569c6] process > LIST_FILES              [100%] 1 of 1 ✔
[0c/d4c9d8] process > SELECT_2024             [100%] 1 of 1 ✔
[81/651b84] process > GENERATE_VIDRL_COMMANDS [100%] 1 of 1 ✔
File: results/files.txt, Lines: 896
File: results/files_2024.txt, Lines: 100
Run VIDRL Script: results/scripts/files_2024_vidrl_script.sh
```