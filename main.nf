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

workflow {
  LIST_FILES()
  | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}
  | SELECT_2024
  | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}
  | GENERATE_VIDRL_COMMANDS
  | view {file -> "Run VIDRL Script: results/scripts/${file.name}"}

  SELECT_2024.out
  | GENERATE_NIID_COMMANDS
  | view {file -> "Run NIID Script: results/scripts/${file.name}"}

  SELECT_2024.out
  | GENERATE_CRICK_COMMANDS
  | view {file -> "Run CRICK Script: results/scripts/${file.name}"}
}