#! /usr/bin/env nextflow

nextflow.enable.dsl = 2

params.filelist = false
params.publishDir = 'results_sera'

process LIST_VIDRL_FILES {
  publishDir params.publishDir, mode: 'copy'
  output: path('files.txt')
  script:
  """
  #! /usr/bin/env bash
  find ~/nextstrain/fludata/VIDRL-Melbourne-WHO-CC | grep "xlsx\$" | grep -v "~" > files.txt
  """
}

process RUN_TITER_BLOCK {
  publishDir "${params.publishDir}/titer_block", mode: 'copy'
  input: path(file)
  output: path("${file.simpleName}_titer_block.txt")
  script:
  """
  #! /usr/bin/env bash
  source ~/miniconda3/etc/profile.d/conda.sh && conda activate fauna
  {
    echo "File: ${file}" >> ${file.simpleName}_titer_block.txt
    ls -ltr >> ${file.simpleName}_titer_block.txt
    readlink $file >> ${file.simpleName}_titer_block.txt
    titer_block.py --file `readlink ${file}` --log-human-sera True >> ${file.simpleName}_titer_block.txt
    if [ \$? -ne 0 ]; then
      echo "Failed to process file: " `readlink $file` >> ${file.simpleName}_titer_block.txt
      exit 0
    fi
  }
  """
}

workflow {
  // List files
  if (params.filelist) {
    xlsx_ch = channel.fromPath(params.filelist)
    | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}
  } else {
    xlsx_ch = LIST_VIDRL_FILES()
    | view {file -> "File: results/${file.name}, Lines: ${file.text.split('\n').size()}"}
  }

  xlsx_ch
  | splitText()
  | RUN_TITER_BLOCK



  //| lines
  //| RUN_TITER_BLOCK
}