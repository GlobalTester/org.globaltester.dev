#!/bin/sh
# must be called from root directory for all repos

. org.globaltester.dev/org.globaltester.dev.tools/releng/helper.sh

CHANGELOG_FILE_NAME="PRODUCT_CHANGELOG"
REPO_CHANGELOG_FILE_NAME="CHANGELOG"
REPOSITORY=$1
RELENG=$2

function cleanup {
	if [ -e "$PREPARED_CHANGELOG" ]
	then
		rm $PREPARED_CHANGELOG
	fi
	if [ -e "$OLD_CHANGELOG" ]
	then
		rm $OLD_CHANGELOG
	fi
	if [ -e "$BUNDLE_VERSION_CHANGES" ]
	then
		rm $BUNDLE_VERSION_CHANGES
	fi
	if [ -e "$CHANGELOG_HEADER" ]
	then
		rm $CHANGELOG_HEADER
	fi
	if [ -e "$CHANGELOG_CONTENT" ]
	then
		rm $CHANGELOG_CONTENT
	fi
}

trap cleanup EXIT

CHANGELOG_HEADER=`mktemp`
CHANGELOG_CONTENT=`mktemp`
PREPARED_CHANGELOG=`mktemp`
OLD_CHANGELOG=`mktemp`
BUNDLE_VERSION_CHANGES=`mktemp`

if [ -e $REPOSITORY/$CHANGELOG_FILE_NAME ]
then
	cat $REPOSITORY/$CHANGELOG_FILE_NAME > $OLD_CHANGELOG
fi

echo -e "Version x.y.z (`date +%d.%m.%Y`)\n" > $CHANGELOG_HEADER

# concatenate condensed logs

# get all repos to be condensed from product aggregator
REPOS_TO_INCLUDE=`cat $REPOSITORY/$RELENG/pom.xml | grep '<module>' | sed -e 's|.*\.\.\/\.\.\/\([^/]*\)\/.*<\/module>|\1|' | sort -u`

for CURRENT_REPO in $REPOS_TO_INCLUDE
do
	echo Checking $CURRENT_REPO
	if [ -e $CURRENT_REPO/$REPO_CHANGELOG_FILE_NAME ]
	then
		#Version x.y.z (`date +%d.%m.%Y`)\n
		cd $CURRENT_REPO
		LAST_TAG=`getLastTag release $REPOSITORY`
		if [ -z "$LAST_TAG" ]
		then
			echo No tagged commit found, skipping
			cd  ..
			continue
		else
			LAST_TAGGED_COMMIT_RANGE=`getLastTagRange release $REPOSITORY`
		
			if [ -z "`git diff --ignore-space-at-eol $LAST_TAG CHANGELOG`" ]
			then
				echo No diff found, skipping
				cd ..
				continue
			fi
			
			GIT_DIFF=`mktemp`
			git diff --ignore-space-at-eol $LAST_TAG $REPO_CHANGELOG_FILE_NAME > $GIT_DIFF
			#TODO better regexp for version grepping, this fails when "Version" occurs in a change log entry
			FIRSTLINE=$((`cat $GIT_DIFF | grep Version -n | head -n 1 | cut -d : -f 1`))
			LASTLINE=$((`cat $GIT_DIFF | grep Version -n | tail -n 1 | cut -d : -f 1` - 1))

			LINES=$(( $LASTLINE - $FIRSTLINE ))
			echo Extracting $LINES lines from lines $FIRSTLINE to $LASTLINE
			echo \# Changelog for Repository: $CURRENT_REPO >> $CHANGELOG_CONTENT
			PRODUCT_VERSION=`echo $LAST_TAG | sed -e "s|.*/.*/\([0-9]\{1,\}\.[0-9]\{1,\}\..*\)|\1|"`
			
			echo \# Last product tagged version was: `cat $GIT_DIFF | head -n $(($LASTLINE + 1)) | tail -n 1` >> $CHANGELOG_CONTENT
			
			BUNDLE_VERSION=`getCurrentVersionFromChangeLog $REPO_CHANGELOG_FILE_NAME`
			
			if [ BUNDLE_VERSION != PRODUCT_VER ]
			then
				echo \* $CURRENT_REPO updated to bundle version $BUNDLE_VERSION >> $BUNDLE_VERSION_CHANGES
			fi
			
			echo >> $CHANGELOG_CONTENT
			cat $GIT_DIFF | head -n $LASTLINE | tail -n $LINES | sed -e "s|^\+\(.*\)|\1|;/^ *$/d;/^$/d" >> $CHANGELOG_CONTENT
			rm $GIT_DIFF
			echo >> $CHANGELOG_CONTENT	
			cd ..
		fi
	fi
done

cat $CHANGELOG_HEADER >> $PREPARED_CHANGELOG
cat $BUNDLE_VERSION_CHANGES >> $PREPARED_CHANGELOG
echo -e "\n" >> $PREPARED_CHANGELOG
cat $CHANGELOG_CONTENT >> $PREPARED_CHANGELOG
echo >> $PREPARED_CHANGELOG
echo \# ---------------------------------------- >> $PREPARED_CHANGELOG
echo \# comments and empty lines will be ignored >> $PREPARED_CHANGELOG
echo \# ---------------------------------------- >> $PREPARED_CHANGELOG

$EDITOR $PREPARED_CHANGELOG

echo -e "\n\n" >> $PREPARED_CHANGELOG
#remove comments
sed -i -e "s|#.*$||g" $PREPARED_CHANGELOG


cat $PREPARED_CHANGELOG $OLD_CHANGELOG > $CHANGELOG_FILE_NAME

cd ..