#!/bin/bash

function extractFieldFromManifest() {
	MANIFESTFILE="$1"
	IDENTIFIER="$2"
	
	LINE=`grep "$IDENTIFIER" "$MANIFESTFILE" -A500 -B0`
	GREPRESULT=$?
	
	if [[ $GREPRESULT != '0' ]]
		then
			return 1
	fi
	
	CLEANEDLINE=`echo "$LINE" | sed "s|^$IDENTIFIER:\s| |; /^[^ ]/q"| sed -e "/^[^ ]/d"`
	
	EXTRACTFIELDRESULT=""
	count=0
	while read -r CURRENTREQUIREMENT
	do
		TMPREQ=$(echo "$CURRENTREQUIREMENT" | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -d ';' -f 1 | cut -d ',' -f 1)
		EXTRACTFIELDRESULT=`echo -e "$EXTRACTFIELDRESULT"'\n'"$TMPREQ"`
	done <<< "$CLEANEDLINE"
	
	EXTRACTFIELDRESULT="$(echo -e "${EXTRACTFIELDRESULT}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')"
	
	echo "$EXTRACTFIELDRESULT"
	
	return 0
}
