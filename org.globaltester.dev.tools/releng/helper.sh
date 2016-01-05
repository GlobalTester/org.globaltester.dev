#!/bin/sh
function getLastTag {
	#$1 tag type, e.g. release
	#$2 product, e.g. de.persosim.rcp
	echo `git tag --list $1/$2/* --sort=version:refname | sed -e '$!d'`
}

function getLastTagRange {
	#$1 tag type, e.g. release
	#$2 product, e.g. de.persosim.rcp
	LAST_TAG=`getLastTag $1 $2`
	if [ -z "$LAST_TAG" ]
	then
		echo No tagged commit found, using the full history
		LAST_TAGGED_COMMIT_ID=
		LAST_TAGGED_COMMIT_RANGE=
	else
		LAST_TAGGED_COMMIT_ID=`git rev-parse $LAST_TAG`
		echo $LAST_TAGGED_COMMIT_ID..
	fi
}

function whereAmI {
	echo `dirname "$(readlink -f "$0")"`
}