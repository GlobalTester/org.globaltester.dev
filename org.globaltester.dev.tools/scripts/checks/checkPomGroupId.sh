#!/bin/bash
#must be called from root directory
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

POM=$1

if [ ! "$POM" ]
then
	echo "Missing parameter: File to check"
	exit 1
fi

#extract values from file
ARTIFACT_ID=`xmlstarlet sel -t -v "/project/artifactId" "$POM"`
GROUP_ID_EXPECTED=`getGroupIdForBundle "$ARTIFACT_ID"`
GROUP_ID_ACTUAL=`xmlstarlet sel -t -v "/project/groupId" "$POM"`

if [ "$GROUP_ID_EXPECTED" != "$GROUP_ID_ACTUAL" ]
then
	echo "$POM : expected groupID $GROUP_ID_EXPECTED but found $GROUP_ID_ACTUAL" 
	if [ -n "$2" -a "$2" == "--auto-fix" ] ; then
		xmlstarlet ed -P --inplace -u "/project/groupId" -v "$GROUP_ID_EXPECTED" "$POM"
		echo fixed!
	fi
fi
