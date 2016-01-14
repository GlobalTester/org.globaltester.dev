#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/releng/helper.sh

CHANGELOG_FILE_NAME="CHANGELOG"
REPOSITORY=$1


function cleanup {
	if [ -e "$PREPARED_CHANGELOG" ]
	then
		rm $PREPARED_CHANGELOG
	fi
	if [ -e "$OLD_CHANGELOG" ]
	then
		rm $OLD_CHANGELOG
	fi
	if [ -e "$CHANGELOG_HEADER" ]
	then
		rm $CHANGELOG_HEADER
	fi
	if [ -e "$CHANGELOG_CONTENT" ]
	then
		rm $CHANGELOG_CONTENT
	fi
	if [ -e "$CHANGELOG_FOOTER" ]
	then
		rm $CHANGELOG_FOOTER
	fi
}

trap cleanup EXIT

PREPARED_CHANGELOG=`mktemp`
OLD_CHANGELOG=`mktemp`
CHANGELOG_CONTENT=`mktemp`
CHANGELOG_HEADER=`mktemp`
CHANGELOG_FOOTER=`mktemp`

cd $REPOSITORY

LAST_TAGGED_COMMIT_RANGE=`getLastTagRange version`

if [ -e $CHANGELOG_FILE_NAME ]
then
	cat $CHANGELOG_FILE_NAME > $OLD_CHANGELOG
else
	touch $CHANGELOG_FILE_NAME
fi

FIRSTLINE=1
SECONDLINE=`getSecondLineNumberContaining "$CHANGELOG_VERSION_REGEXP" $OLD_CHANGELOG`
cat $OLD_CHANGELOG | tail -n $((`cat $OLD_CHANGELOG | sed -e '$a\' | wc -l` - $SECONDLINE + 1 )) > $CHANGELOG_FOOTER


LAST_TAG=`getLastTag version`

VERSION_NEEDED=1

if [ ! -z "$LAST_TAG" ]
then
	GIT_DIFF=`mktemp`
	extractGitDiffSinceCommit $LAST_TAG $CHANGELOG_FILE_NAME $GIT_DIFF
	
	if [ ! -z "`cat $GIT_DIFF`" ]
	then
		FIRSTLINE=$(( `getFirstLineNumberContaining "@@.*@@" "$GIT_DIFF"` + 1))
		FIRSTLINE_WITH_VERSION=`getFirstLineNumberContaining "$CHANGELOG_VERSION_REGEXP" "$GIT_DIFF"`
		LASTLINE=`getLastLineNumberContaining "$CHANGELOG_VERSION_REGEXP" "$GIT_DIFF"`
		
		if [ $LASTLINE == $FIRSTLINE_WITH_VERSION ]
		then
			VERSION_NEEDED=0
		fi
		
		extractLinesFromDiff $FIRSTLINE $LASTLINE $GIT_DIFF | sed -e "s|^\+\(.*\)|\1|" >> $CHANGELOG_CONTENT
	fi
	
	rm $GIT_DIFF
fi

if [ $VERSION_NEEDED -eq 1 ]
then
	echo -e "Version $DUMMY_VERSION (`getCurrentDate`)\n" > $CHANGELOG_HEADER
fi

git log --format="* %<|(85)%s $LOG_MESSAGE_DIVIDER %h %an" $LAST_TAGGED_COMMIT_RANGE >> $CHANGELOG_CONTENT
if [ ! -z "`cat $CHANGELOG_CONTENT`" ]
then
	echo \# Condense changes for repository $REPOSITORY > $PREPARED_CHANGELOG
	if [ ! -z "$LAST_TAG" ]
	then
		echo \# The base tag for this update is $LAST_TAG >> $PREPARED_CHANGELOG
	else
		echo \# The repository was not version tagged before >> $PREPARED_CHANGELOG
	fi
	echo \# Comments and empty lines will be ignored >> $PREPARED_CHANGELOG
	echo \# ---------------------------------------- >> $PREPARED_CHANGELOG
	cat $CHANGELOG_HEADER >> $PREPARED_CHANGELOG
	cat $CHANGELOG_CONTENT >> $PREPARED_CHANGELOG

	$EDITOR $PREPARED_CHANGELOG

	sed -i -e '/^#/d; s|#.*||' -e "s|$LOG_MESSAGE_DIVIDER.*||" -e 's|\s*$||' -e "/^$/d" -e "s|$CHANGELOG_VERSION_REGEXP|&\n|" $PREPARED_CHANGELOG
	
	if [ ! -z "`cat $PREPARED_CHANGELOG`" ]
	then
		echo -e "\n" >> $PREPARED_CHANGELOG
	fi
	
	cat $PREPARED_CHANGELOG $CHANGELOG_FOOTER > $CHANGELOG_FILE_NAME
else
	echo "No changes, skipping"
fi

cd ..

#TODO version Version when no correct version can be parsed
#TODO missing new line between repos
#TODO version comment not removed after editing