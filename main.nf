#! /usr/bin/env nextflow

nextflow.enable.dsl = 2



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
  input: tuple path(vidrl_script), path(niid_script), path(crick_script)
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
  bash ${vidrl_script}
  sleep 3
  # bash ${niid_script}
  # sleep 3
  # bash ${crick_script}
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
  xlsx_ch = LIST_FILES()
  | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}
  //| SELECT_2024
  | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}

  xlsx_ch
  | GENERATE_VIDRL_COMMANDS
  | view {file -> "Run VIDRL Script: results/scripts/${file.name}"}

  xlsx_ch
  | GENERATE_NIID_COMMANDS
  | view {file -> "Run NIID Script: results/scripts/${file.name}"}

  xlsx_ch
  | GENERATE_CRICK_COMMANDS
  | view {file -> "Run CRICK Script: results/scripts/${file.name}"}

  GENERATE_VIDRL_COMMANDS.out
  | combine(GENERATE_NIID_COMMANDS.out)
  | combine(GENERATE_CRICK_COMMANDS.out)
  | RUN_GENERATED_SCRIPTS

  FETCH_FAUNA_COUNTS()

  my_log_ch = RUN_GENERATED_SCRIPTS.out | map { it -> [it.get(1)]}

  fauna_counts_ch = FETCH_FAUNA_COUNTS.out | map { it -> [it.get(0)]}

  channel.of('vidrl')
  | combine(my_log_ch)
  | combine(fauna_counts_ch)
  | COMPARE_COUNTS
  | view {file -> "Comparing results: results/${file.name}"}
}