#! /usr/bin/env bash

while read LINE ; do
  if [[ $LINE == *"VIDRL"* ]]; then
    DST_FILE="$LINE"
    FILENAME=`echo $DST_FILE | awk -F'/' '{print $12}' | sed 's/\..*//g' `
    SUBTYPE=`echo $DST_FILE | awk -F'/' '{print $9}' |sed 's/Victoria/vic/g' | sed 's/H1N1pdm/h1n1pdm/g' | sed 's/H3N2/h3n2/g'`
    FILEPATH=$(dirname "$DST_FILE")
    ASSAY=`echo $DST_FILE | awk -F'/' '{print $10}' | sed 's/HI/hi/g' | sed 's/FRA/fra/g'`
    LOGFILE="my_log/vidrl_${FILENAME}.txt"

    cat << EOF
echo "$DST_FILE" > $LOGFILE
envdir ~/nextstrain/env.d/seasonal-flu/ \\
  python tdb/vidrl_upload.py \\
  -db vidrl_tdb \\
  --virus flu \\
  --subtype ${SUBTYPE} \\
  --assay_type ${ASSAY} \\
  --path $FILEPATH/ \\
  --fstem $FILENAME \\
  --ftype vidrl \\
  --preview &>> $LOGFILE
echo "visidata data/tmp/$FILENAME.tsv" >> $LOGFILE
sleep 1

EOF

  fi
done < $1
