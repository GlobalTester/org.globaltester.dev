#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

CHANGELOG_FILE_NAME="CHANGELOG"
REPOSITORY=$1
RELENG=$2

if [ -z "$RELENG" ]
then
	RELENG="$REPOSITORY.releng"
fi

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

CHANGELOG_HEADER=`mktemp`
CHANGELOG_FOOTER=`mktemp`
CHANGELOG_CONTENT=`mktemp`
PREPARED_CHANGELOG=`mktemp`
OLD_CHANGELOG=`mktemp`

if [ -e $REPOSITORY/$CHANGELOG_FILE_NAME ]
then
	cat $REPOSITORY/$CHANGELOG_FILE_NAME > $OLD_CHANGELOG
fi


cd $REPOSITORY

FIRSTLINE=`getFirstLineNumberContaining "$CHANGELOG_VERSION_REGEXP" $CHANGELOG_FILE_NAME`
LASTLINE=`getSecondLineNumberContaining "$CHANGELOG_VERSION_REGEXP" $CHANGELOG_FILE_NAME`
LINES=$(( $LASTLINE - $FIRSTLINE ))

if [ $LINES -eq 0 ]
then
	echo -e "Version $DUMMY_VERSION (`getCurrentDate`)\n" > $CHANGELOG_HEADER
	GIT_DIFF=`mktemp`
	extractGitDiffSinceCommit HEAD $CHANGELOG_FILE_NAME $GIT_DIFF
	LASTLINE_IN_DIFF=$((`getFirstLineNumberContaining "$CHANGELOG_VERSION_REGEXP" "$GIT_DIFF"` - 1))
	FIRSTLINE_IN_DIFF=$(( `getFirstLineNumberContaining "@@.*@@" "$GIT_DIFF"`))
	extractLinesFromDiff $FIRSTLINE_IN_DIFF $LASTLINE_IN_DIFF $GIT_DIFF | sed -e "s|^\+\(.*\)|\1|" -e "s|$CHANGELOG_VERSION_REGEXP|# &|" | sed -e "/^ *$/d;/^$/d" >> $CHANGELOG_HEADER
else
	cat $OLD_CHANGELOG | head -n $(($LASTLINE - 1)) | tail -n $LINES > $CHANGELOG_HEADER
fi

cat $OLD_CHANGELOG | tail -n $((`cat $OLD_CHANGELOG | sed -e '$a\' | wc -l` - $LASTLINE + 1 )) > $CHANGELOG_FOOTER

# get all repos to be condensed from product aggregator
REPOS_TO_INCLUDE=`getRepositoriesFromAggregator $RELENG/pom.xml $REPOSITORY`

# get overall last tagged product version
LAST_TAGGED_PRODUCT_VERSION=`getLastTag release $REPOSITORY | sed -e "s|.*/.*/\($VERSION_REGEXP_PATCH_LEVEL_EVERYTHING\)|\1|"`
cd ..
for CURRENT_REPO in $REPOS_TO_INCLUDE
do
	if [ -e $CURRENT_REPO/$CHANGELOG_FILE_NAME ]
	then
		cd $CURRENT_REPO
		BUNDLE_VERSION=`getCurrentVersionFromChangeLog $CHANGELOG_FILE_NAME`
		LAST_TAG=`getLastTag release $REPOSITORY`
		if [ ! -z "$LAST_TAG" ]
		then
			PRODUCT_VERSION=`echo $LAST_TAG | sed -e "s|.*/.*/\($VERSION_REGEXP_PATCH_LEVEL_EVERYTHING\)|\1|"`
			GIT_DIFF=`mktemp`
			extractGitDiffSinceCommit $LAST_TAG $CHANGELOG_FILE_NAME $GIT_DIFF
			if [ ! -z "`cat $GIT_DIFF`" ]
			then
				FIRSTLINE=`getFirstLineNumberContaining "$CHANGELOG_VERSION_REGEXP" "$GIT_DIFF"`
				LASTLINE=`getLastLineNumberContaining "$CHANGELOG_VERSION_REGEXP" "$GIT_DIFF"`
				
				if [ $LAST_TAGGED_PRODUCT_VERSION != $PRODUCT_VERSION ]
				then 
					echo \# WARNING: Last tagged version for this repository was: $PRODUCT_VERSION but should be $LAST_TAGGED_PRODUCT_VERSION >> $CHANGELOG_CONTENT	
				fi
				
				LAST_TAGGED_REPO_VERSION=`cat $GIT_DIFF | head -n $(($LASTLINE + 1)) | tail -n 1 | sed -e "s|Version \($VERSION_REGEXP_PATCH_LEVEL_NO_WHITESPACE\).*|\1|"`
				
				if [ "$BUNDLE_VERSION" != "$LAST_TAGGED_REPO_VERSION" ]
				then
					echo \* $CURRENT_REPO updated to version $BUNDLE_VERSION >> $CHANGELOG_CONTENT
				fi
							
				extractLinesFromDiff $FIRSTLINE $LASTLINE $GIT_DIFF | sed -e "s|^\+\(.*\)|\1|" -e "s|^.*$CHANGELOG_VERSION_REGEXP|# &|" -e "/^ *$/d;/^$/d;" -e "s|[^#].*|$SPACER&|" >> $CHANGELOG_CONTENT
				echo >> $CHANGELOG_CONTENT
			else
				echo No diff found, skipping
			fi
			
			rm $GIT_DIFF
		else
			echo \* $CURRENT_REPO contained in version $BUNDLE_VERSION >> $CHANGELOG_CONTENT
			cat $CHANGELOG_FILE_NAME | sed -e "s|^.*$CHANGELOG_VERSION_REGEXP|# &|" -e "s|[^#].*|$SPACER&|" -e "/^\s*$/d"  >> $CHANGELOG_CONTENT
			removeLeadingAndTrailingEmptyLines $CHANGELOG_CONTENT
			echo >> $CHANGELOG_CONTENT
		fi
		cd ..
	fi
done

removeLeadingAndTrailingEmptyLines $CHANGELOG_HEADER

echo \# Condense downstream changes for product $REPOSITORY > $PREPARED_CHANGELOG
if [ ! -z "$LAST_TAGGED_PRODUCT_VERSION" ]
then
	echo \# The base tag for this update is $LAST_TAGGED_PRODUCT_VERSION >> $PREPARED_CHANGELOG
else
	echo \# The product was not version tagged before >> $PREPARED_CHANGELOG
fi
echo \# Comments and empty lines at the end will be ignored >> $PREPARED_CHANGELOG
echo \# ---------------------------------------- >> $PREPARED_CHANGELOG
cat $CHANGELOG_HEADER >> $PREPARED_CHANGELOG
echo >> $PREPARED_CHANGELOG
cat $CHANGELOG_CONTENT >> $PREPARED_CHANGELOG

$EDITOR "$PREPARED_CHANGELOG"

removeComments "$PREPARED_CHANGELOG"
removeLeadingAndTrailingEmptyLines "$PREPARED_CHANGELOG"


if [ `head -n 1 "$PREPARED_CHANGELOG" | grep "$CHANGELOG_VERSION_REGEXP" | wc -l` -eq 0 ]
then
	echo "ERROR: $CHANGELOG_FILE_NAME does not contain a valid version string in the first line"
	exit 1
fi

cat $PREPARED_CHANGELOG > $REPOSITORY/$CHANGELOG_FILE_NAME
echo >> $REPOSITORY/$CHANGELOG_FILE_NAME
cat $CHANGELOG_FOOTER >> $REPOSITORY/$CHANGELOG_FILE_NAME

cd ..
