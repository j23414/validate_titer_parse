#! /usr/bin/env nextflow

nextflow.enable.dsl = 2

params.filelist = false
params.fauna_counts = false
params.my_log = false

process LIST_FILES {
  publishDir 'results', mode: 'copy'
  output: path('files.txt')
  script:
  """
  #! /usr/bin/env bash
  list_files.sh > files.txt
  """
}

process SELECT_2024 {
  publishDir 'results', mode: 'copy'
  input: path(filelist)
  output: path("${filelist.simpleName}_2024.txt")
  script:
  """
  #! /usr/bin/env bash
  grep "/2024/" ${filelist} > ${filelist.simpleName}_2024.txt
  """
}

process GENERATE_VIDRL_COMMANDS {
  publishDir 'results/scripts', mode: 'copy'
  input: path(filelist)
  output: path("${filelist.simpleName}_vidrl_script.sh")
  script:
  """
  #! /usr/bin/env bash
  gen_vidrl_cmd.sh ${filelist} > ${filelist.simpleName}_vidrl_script.sh
  """
}

process GENERATE_NIID_COMMANDS {
  publishDir 'results/scripts', mode: 'copy'
  input: path(filelist)
  output: path("${filelist.simpleName}_niid_script.sh")
  script:
  """
  #! /usr/bin/env bash
  gen_niid_cmd.sh ${filelist} > ${filelist.simpleName}_niid_script.sh
  """
}

process GENERATE_CRICK_COMMANDS {
  publishDir 'results/scripts', mode: 'copy'
  input: path(filelist)
  output: path("${filelist.simpleName}_crick_script.sh")
  script:
  """
  #! /usr/bin/env bash
  gen_crick_cmd.sh ${filelist} > ${filelist.simpleName}_crick_script.sh
  """
}

process RUN_GENERATED_SCRIPTS {
  publishDir 'results', mode: 'copy'
  input: path(source_script) //, path(niid_script), path(crick_script)
  output: tuple path("data/tmp/*"), path("my_log/*")
  script:
  """
  #! /usr/bin/env bash
  source ~/miniconda3/etc/profile.d/conda.sh && conda activate fauna
  export PYTHONPATH="/Users/jchang3/nextstrain/fauna:\$PYTHONPATH"

  ln -s ~/nextstrain/fauna/tdb .
  ln -s ~/nextstrain/fauna/source-data .
  mkdir -p data/tmp
  mkdir -p my_log
  bash ${source_script}
  sleep 5
  """
}

process FETCH_FAUNA_COUNTS {
  publishDir 'results', mode: 'copy'
  output: tuple path("fauna_counts/*"), path("fauna_data/*")
  script:
  """
  #! /usr/bin/env bash
  source ~/miniconda3/etc/profile.d/conda.sh && conda activate fauna
  export PYTHONPATH="/Users/jchang3/nextstrain/fauna:\$PYTHONPATH"

  ln -s ~/nextstrain/fauna/tdb .
  ln -s ~/nextstrain/fauna/source-data .
  mkdir -p data/
  bash fetch_fauna_counts.sh
  mv data fauna_data
  mv counts fauna_counts
  """
}

process COMPARE_COUNTS {
  publishDir 'results', mode: 'copy'
  input: tuple val(source), path(my_log), path(fauna_counts)
  output: tuple path("results_${source}.txt"), path("flagged_${source}.txt")
  script:
  """
  #! /usr/bin/env bash
  bash compare_counts.sh $source
  """
}

workflow {
  // List files
  if (params.filelist) {
    xlsx_ch = channel.fromPath(params.filelist)
    | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}
  } else {
    xlsx_ch = LIST_FILES()
    | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}
    //| SELECT_2024
    | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}
  }

  // Fauna counts
  if(params.fauna_counts) {
    fauna_counts_ch = channel.fromPath(params.fauna_counts)
    | collect
    | map { it -> [it]}
  } else {
    fauna_counts_ch = FETCH_FAUNA_COUNTS
    | map { it -> [it.get(0)]}
  }

  if(params.my_log) {
    my_log_ch = channel.fromPath(params.my_log)
    | collect
    | map { it -> [it]}

  } else {
    // xlsx_ch
    // | GENERATE_VIDRL_COMMANDS
    // | view {file -> "Run VIDRL Script: results/scripts/${file.name}"}

    xlsx_ch
    | GENERATE_NIID_COMMANDS
    | view {file -> "Run NIID Script: results/scripts/${file.name}"}

    // xlsx_ch
    // | GENERATE_CRICK_COMMANDS
    // | view {file -> "Run CRICK Script: results/scripts/${file.name}"}

    my_log_ch = // GENERATE_VIDRL_COMMANDS.out
    GENERATE_NIID_COMMANDS.out
    | RUN_GENERATED_SCRIPTS
    | map { it -> [it.get(1)]}
  }

  channel.of('niid')
  | combine(my_log_ch)
  | combine(fauna_counts_ch)
  | COMPARE_COUNTS
  | view {file -> "Comparing results: results/${file.name}"}
}