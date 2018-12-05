#!/bin/bash

: ${KNORA_BULK_ENDPOINT:=http://localhost:3333/v1/resources/xmlimport/}
: ${KNORA_USER:=root@example.com:test}

if [ "$#" -ne 2 ]; then
    echo -e "Usage: $0 images_folder image_xml_path"
    echo "KNORA_BULK_ENDPOINT=$KNORA_BULK_ENDPOINT"
    echo "KNORA_USER=$KNORA_USER"
    echo "to set new BULK_ENDPOINT:"
    echo 'export KNORA_BULK_ENDPOINT="https://knora-nv.unil.ch/v1/resources/xmlimport/"'
    exit 1
fi

echo "KNORA_BULK_ENDPOINT=$KNORA_BULK_ENDPOINT"
echo "KNORA_USER=$KNORA_USER"

BULK_HEADER="<?xml version=\"1.0\" encoding=\"UTF-8\"?><knoraXmlImport:resources xmlns=\"http://api.knora.org/ontology/0001/anything/xml-import/v1#\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://api.knora.org/ontology/0001/anything/xml-import/v1# p0001-anything.xsd\" xmlns:p0001-anything=\"http://api.knora.org/ontology/0001/anything/xml-import/v1#\" xmlns:knoraXmlImport=\"http://api.knora.org/ontology/knoraXmlImport/v1#\">"
BULK_FOOTER="</knoraXmlImport:resources>"
BULK_TEMPLATE_FILE="ThingPicture-template.xml"

warn_count=0
error_count=0
count_entries=0
files=($(find $1 -maxdepth 1 -type f -not -name ".*" | sort))
count_files=${#files[@]}
allbulk_file=/tmp/allbulk-$(date +%s)
image_xml_path=$2
echo ${BULK_HEADER} > $allbulk_file
echo "Found $count_files file(s)"

echo "--> Bulk Test BEGIN $(date)"
echo ""
fileCount=0
for (( i=0; i<${count_files}; i++ ));
do
    ((fileCount++))
    d=$(date +%s)
    file=${files[$i]}
    filename=$(basename -- "$file")
    extension="${filename##*.}"
    type=""
    type=$(grep $extension":" mimetypes | cut -d":" -f2)
    if [ "$type" == "" ]; then
        echo "    -${fileCount}/${count_files}-  file=$file"
        echo "    ### WARNING $file ignored, cannot find file type from mimetypes file"
        echo ""
        ((warn_count++))
    else
        bulk_file=/tmp/bulk-$d
        base_filename=$(basename $file)
        bulk=$(sed -e 's,@@FILE_PATH@@,'"${image_xml_path}/${base_filename}"',g' -e 's,@@MIMETYPE@@,'"$type"',g' -e 's,@@DATE_EPOCH@@,'"$d"',g'  ${BULK_TEMPLATE_FILE})
        echo "    -${fileCount}/${count_files}- bulk id=$d file=$file ($(date))"
        echo ${BULK_HEADER} > $bulk_file
        echo $bulk >> $bulk_file        
        echo $bulk >> $allbulk_file        
        echo ${BULK_FOOTER} >> $bulk_file
        cmd="curl -k -s -u ${KNORA_USER} -X POST -d @$bulk_file ${KNORA_BULK_ENDPOINT}http%3A%2F%2Frdfh.ch%2Fprojects%2F0001"
        echo "      CMD: $cmd"
        response=$($cmd)
        if [[ $response =~ .*createdResources.* ]] ; then
            ((count_entries++))
            echo "    ### SUCCESS $file"
        else
            echo ""
            echo "    "$(cat $bulk_file)
            echo "    ### ERROR $file"
            echo "    $response"
            ((error_count++))
        fi
        echo ""
        # wait 1s to avoid id collision based on seconds from epoch
        sleep 1
    fi
done
echo ""
echo "<-- Bulk Test END $(date)"

echo "#### FOUND ${count_entries} ENTRIES"

if [ $warn_count != 0 ]; then
    echo "#### $warn_count WARNING(S) FOUND: CHECK LOGS ABOVE"
else
    echo "#### NO WARNING FOUND"
fi
if [ $error_count != 0 ]; then
    echo "#### $error_count ERROR(S) FOUND: CHECK LOGS ABOVE"
else
    echo "#### NO ERROR FOUND"
fi

echo ""
echo "--> full bulk with ${count_entries} entries - file=$allbulk_file ($(date))"
echo ${BULK_FOOTER} >> $allbulk_file
cmd="curl -k -s -u ${KNORA_USER} -X POST -d @$allbulk_file ${KNORA_BULK_ENDPOINT}http%3A%2F%2Frdfh.ch%2Fprojects%2F0001"
echo " CMD: $cmd"
response=$($cmd)
if [[ $response =~ .*createdResources.* ]] ; then
  echo "    ### SUCCESS full bulk import: $allbulk_file"
else
  echo ""
  echo "    ### ERROR full bulk import: $allbulk_file"
  echo "    $response"
fi
echo ""
echo "<-- all bulk file=$allbulk_file ($(date))"


