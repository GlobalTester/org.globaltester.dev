#!/bin/sh
SPACER="  "
ONE_OR_MORE_DECIMALS_REGEXP="[0-9]\{1,\}"
VERSION_REGEXP_NO_PATCH_LEVEL="$ONE_OR_MORE_DECIMALS_REGEXP\.$ONE_OR_MORE_DECIMALS_REGEXP\."
VERSION_REGEXP_PATCH_LEVEL_EVERYTHING="$VERSION_REGEXP_NO_PATCH_LEVEL.*"
VERSION_REGEXP_PATCH_LEVEL_NO_WHITESPACE="$VERSION_REGEXP_NO_PATCH_LEVEL[^\s]*"
VERSION_REGEXP_PATCH_LEVEL_NO_LT="$VERSION_REGEXP_NO_PATCH_LEVEL[^<]*"
DATE_REGEXP="${ONE_OR_MORE_DECIMALS_REGEXP}\.${ONE_OR_MORE_DECIMALS_REGEXP}\.${ONE_OR_MORE_DECIMALS_REGEXP}"
CHANGELOG_VERSION_REGEXP="Version ${VERSION_REGEXP_NO_PATCH_LEVEL}.* ($DATE_REGEXP)"
DUMMY_VERSION="x.y.z"
LOG_MESSAGE_DIVIDER=`echo -e "\xe2\x9c\x96"`
CHANGELOG_FILE_NAME=CHANGELOG

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

function extractLinesFromDiff {
	FIRSTLINE=$1
	LASTLINE=$2
	DIFF=$3
	LINES=$(( $LASTLINE - $FIRSTLINE ))

	cat $DIFF | head -n $LASTLINE | tail -n $LINES
}

function getFirstLineNumberContaining {
	REGEXP=$1
	FILE=$2
	cat $FILE | grep "$REGEXP" -n | head -n 1 | cut -d : -f 1
}

function getSecondLineNumberContaining {
	REGEXP=$1
	FILE=$2
	cat $FILE | grep "$REGEXP" -n | head -n 2 | tail -n 1 | cut -d : -f 1
}

function getLastLineNumberContaining {
	REGEXP=$1
	FILE=$2
	cat $FILE | grep "$REGEXP" -n | tail -n 1 | cut -d : -f 1
}

function extractGitDiffSinceCommit {
	COMMIT=$1
	FILENAME=$2
	RESULT_FILE=$3
	
	git diff --ignore-space-at-eol $LAST_TAG $CHANGELOG_FILE_NAME > $GIT_DIFF
}

function getRepositoriesFromAggregator {
	POM_FILE=$1
	REPOSITORY=$2
	GREP_COMMAND=
	if [ ! -z "$REPOSITORY" ]
	then
		GREP_COMMAND="| grep -v $REPOSITORY"
	fi
	#TODO replace eval with safer alternative
	eval "cat $POM_FILE | grep '<module>' $GREP_COMMAND | sed -e 's|.*\.\.\/\.\.\/\([^/]*\)\/.*<\/module>|\1|' | sort -u"
}

function removeLeadingAndTrailingEmptyLines {
	# Delete empty lines at begin of file
	sed -i -e '/./,$!d' $1
	# Delete empty lines at end of file
	sed -i -e :a -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' $1
}

function removeComments {
	# Delete comments
	sed -i -e '/^#/d;' $1
	sed -i -e "s|\s*$LOG_MESSAGE_DIVIDER.*||" $1
}

function getCurrentDate {
	date +%d.%m.%Y
}

function whereAmI {
	echo `dirname "$(readlink -f "$0")"`
}