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

#BASH_OPTIONS="-x"
BASH_OPTIONS=""

function getLastTag {
	#$1 tag type, e.g. release
	#$2 type qualifier, e.g. de.persosim.rcp for products
	if [ -z "$2" ]
	then
		FILTER="$1/*"
	else
		FILTER="$1/$2/*"
	fi

	echo `git tag --list $FILTER | sort -V | sed -e '$!d'`
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

function getChangeLogFileForRepo {
	if [[ $1 =~ ^(org)|(com\.secunet)\.globaltester ]];
	then
		echo "org.globaltester.platform/$CHANGELOG_FILE_NAME"
	elif [[ $1 =~ ^(de)|(com\.secunet)\.persosim ]];
	then
		echo "de.persosim.rcp/$CHANGELOG_FILE_NAME"
	elif [[ $1 =~ ^com\.secunet\.poseidas ]];
	then
		echo "com.secunet.poseidas/$CHANGELOG_FILE_NAME"
	fi
}

function getCurrentDateFromChangeLog {
	CHANGELOG_FILE=`getChangeLogFileForRepo $1`
	if [ ! $CHANGELOG_FILE ] ; then return; fi

	while read CURRENT_LINE; do
		VERSION=`echo $CURRENT_LINE | sed -e 's|Version \([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\) (\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\))|\2|g'`
		if [ ! -z "$VERSION" ]
		then
			echo $VERSION
			break
		fi
	done < $CHANGELOG_FILE
}

function getCurrentVersionFromChangeLog {
	CHANGELOG_FILE=`getChangeLogFileForRepo $1`
	if [ ! $CHANGELOG_FILE ] ; then return; fi

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
	LINES=$(( $LASTLINE - $FIRSTLINE + 1))

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

	git diff -U0 --ignore-space-at-eol $LAST_TAG $CHANGELOG_FILE_NAME > $GIT_DIFF
}

function getRepositoriesFromAggregator {
	POM_FILE=$1

	cat $POM_FILE | grep '<module>' | sed -e 's|.*\.\.\/\.\.\/\([^/]*\)\/.*<\/module>.*|\1|' | sort -u
}

function getRepositoriesFromModules {
	MODULES_FILE=$1

	cat $MODULES_FILE | sed -e 's|.*\.\.\/\.\.\/\([^/]*\)\/.*|\1|' | sort -u
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

function removeTrailingWhitespace {
	sed -i -e "s|\s*&||" $1
}

function getCurrentDate {
	date +%d.%m.%Y
}

function getAbsolutePath {
	ABS_PATH=`readlink -f "$1"`

	if command -v cygpath >/dev/null 2>&1
	then
		ABS_PATH=`cygpath -w $ABS_PATH`
	fi

	echo "$ABS_PATH"
}

function getGroupIdForBundle {
	if [[ $1 =~ ^org\.globaltester ]];
	then
		echo "org.globaltester"
	elif [[ $1 =~ ^de\.persosim ]];
	then
		echo "de.persosim"
	elif [[ $1 =~ ^com\.secunet\.globaltester ]];
	then
		echo "com.secunet.globaltester"
	elif [[ $1 =~ ^com\.secunet\.persosim ]];
	then
		echo "com.secunet.persosim"
	elif [[ $1 =~ ^com\.secunet\.poseidas ]];
	then
		echo "com.secunet.poseidas"
	elif [[ $1 =~ ^com\.secunet ]];
	then
		echo "com.secunet"
	else
		echo "unkown"
	fi
}
