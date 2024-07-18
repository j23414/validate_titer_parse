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

workflow {
  LIST_FILES()
  | view {file -> "File: ${file.name}, Lines: ${file.text.split('\n').size()}"}
  | SELECT_2024
  | view {file -> "File: ${file.name}, Lines: ${file.text.split('\n').size()}"}
}