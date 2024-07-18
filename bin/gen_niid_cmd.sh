#! /usr/bin/env bash

while read LINE ; do
  if [[ $LINE == *"NIID"* ]]; then
    DST_FILE=`echo "$LINE"  | sed 's:(:\\\(:g' | sed 's:):\\\):g'`
    FILENAME=`echo $DST_FILE | awk -F'/' '{print $12}' | sed 's/\..*//g' `
    SUBTYPE=`echo $DST_FILE | awk -F'/' '{print $9}' |sed 's/Victoria/vic/g' | sed 's/H1N1pdm/h1n1pdm/g' | sed 's/H3N2/h3n2/g'`
    FILEPATH=$(dirname "$LINE")
    ASSAY=`echo $DST_FILE | awk -F'/' '{print $10}' | sed 's/HI/hi/g' | sed 's/FRA/fra/g'`
    LOGFILE="my_log/niid_${FILENAME}.txt"

    cat << EOF
echo "$DST_FILE" > $LOGFILE
envdir ~/nextstrain/env.d/seasonal-flu/ \\
  python tdb/niid_upload.py \\
  -db niid_tdb \\
  --virus flu \\
  --subtype ${SUBTYPE} \\
  --assay_type ${ASSAY} \\
  --path $FILEPATH/ \\
  --fstem $FILENAME \\
  --ftype niid \\
  --preview &>> $LOGFILE
echo "visidata data/tmp/$FILENAME.tsv" >> $LOGFILE
sleep 1

EOF

  fi
done < $1