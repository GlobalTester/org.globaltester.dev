#!/bin/sh
function getLastTag {
	#$1 tag type, e.g. release
	#$2 type qualifier, e.g. de.persosim.rcp for products
	if [ -z "$2" ]
	then
		FILTER="$1/*"
	else
		FILTER="$1/$2/*"
	fi
	
	echo `git tag --list $FILTER --sort=version:refname | sed -e '$!d'`
}

function getLastTagRange {
	#$1 tag type, e.g. release
	#$2 type qualifier, e.g. de.persosim.rcp for products
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

function getCurrentVersionFromChangeLog {
	CHANGELOG_FILE=$1
	while read CURRENT_LINE; do
		VERSION=`echo $CURRENT_LINE | sed -e 's|Version \([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\) ([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\})|\1|g'`
		if [ ! -z "$VERSION" ]
		then
			echo $VERSION
			break
		fi
	done < $CHANGELOG_FILE
}

function getChangeLogSinceVersion {
	CHANGELOG_FILE=$1
	VERSION_TO_SEARCH=$2
	RESULT=`mktemp`
	while read CURRENT_LINE; do
		VERSION=`echo $CURRENT_LINE | sed -e 's|Version \([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\) ([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\})|\1|g'`
		if [ $VERSION == $VERSION_TO_SEARCH ]
		then
			break
		else
			if [ ! -z "$VERSION" ]
			then
				$CURRENT_LINE"\n" >> $RESULT
			fi
		fi
	done < $CHANGELOG_FILE
	cat $RESULT
	rm $RESULT
}

function whereAmI {
	echo `dirname "$(readlink -f "$0")"`
}