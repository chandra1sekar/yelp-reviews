#!/bin/bash

#
# You have to preprocess raw yelp_review.csv file like the below:
## use | as seperator
# sed 's/","/"|"/g' < yelp_review.csv > modified_yelp_review.csv
## remove newline \n inside double quote
# awk '/^"/ {if (f) print f; f=$0; next} {f=f FS $0} END {print f}' modified_yelp_review.csv > new.csv
# mv new.csv modified_yelp_review.csv

INPUT=modified_yelp_review.csv
OLDIFS=$IFS
IFS='|'
BINARIZE_THREASHOLD=2.0
NUM_OF_DATA_PER_LABEL=15000
#NUM_OF_DATA_PER_LABEL=15
previews=0
nreviews=0
line=0
DATAFILE="data.csv"
start_line_no=5

[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

echo "#review text" > "${DATAFILE}"

while read review_id user_id business_id stars date text useful funny cool
do
    if [[ ($previews -ge ${NUM_OF_DATA_PER_LABEL}) && ($nreviews -ge ${NUM_OF_DATA_PER_LABEL}) ]]; then
        echo "Selected enough data, positive:" $previews, "negative:" $nreviews
        break
    fi
    ((line=line+1))
    if (( ${line} % 1000 == 0 )); then
        echo "line = ", ${line}, ", positive = ", ${previews}, ", negative = ", ${nreviews}
    fi
    if [[ ${line} -lt ${start_line_no} ]]; then
        continue
    fi
    #echo "Parse data from $line"
    if [[ (! "x$stars" = "x") && (! "x$text" = "x") ]]; then
        new_text=`sed -e 's/^"//' -e 's/"$//' <<<"$text"`
        new_stars=`sed -e 's/^"//' -e 's/"$//' <<<"$stars"`
        if [[ ($new_stars =~ ^[+-]?[0-9]+\.?[0-9]*$) && ("${#new_text}" -ge 15) ]]; then
            if (( $(echo "$new_stars > ${BINARIZE_THREASHOLD}" | bc -l) )); then
                if [[ ($previews -lt ${NUM_OF_DATA_PER_LABEL}) ]]; then
                    ((previews=previews+1))
                    echo $new_text,"|1" >> "${DATAFILE}"
                fi
            else
                if [[ ($nreviews -lt ${NUM_OF_DATA_PER_LABEL}) ]]; then
                    ((nreviews=nreviews+1))
                    echo $new_text,"|0" >> "${DATAFILE}"
                fi
            fi
        fi
    fi
done < $INPUT
IFS=$OLDIFS

# Remove comma from text since it's taken as seperator in the numpy load function
sed 's/,/ /g' "${DATAFILE}" > "new.csv"
mv "new.csv" "${DATAFILE}"
