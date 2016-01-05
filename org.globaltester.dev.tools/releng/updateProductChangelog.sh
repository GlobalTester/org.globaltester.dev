#!/bin/sh
# must be called from root directory for all repos

. org.globaltester.dev/org.globaltester.dev.tools/releng/helper.sh

CHANGELOG_FILE_NAME="PRODUCT_CHANGELOG"
REPO_CHANGELOG_FILE_NAME="CHANGELOG"
REPOSITORY=$1
RELENG=$2

function cleanup {
	if [ ! -z "$TEMPFILE" ]
	then
		rm $TEMPFILE
	fi
}

trap cleanup EXIT

PREPARED_CHANGELOG=`mktemp`
OLD_CHANGELOG=`mktemp`

if [ -e $REPOSITORY/$CHANGELOG_FILE_NAME ]
then
	cat $REPOSITORY/$CHANGELOG_FILE_NAME > $OLD_CHANGELOG
fi

echo -e "Version x.y.z (`date +%d.%m.%Y`)\n" > $PREPARED_CHANGELOG

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
			LAST_TAGGED_COMMIT_ID=`git rev-parse $LAST_TAG`
			LAST_TAGGED_COMMIT_RANGE=$LAST_TAGGED_COMMIT_ID..
		
			if [ -z "`git diff --ignore-space-at-eol $LAST_TAG CHANGELOG`" ]
			then
				echo No diff found, skipping
				cd ..
				continue
			fi
			
			FIRSTLINE=$((`git diff --ignore-space-at-eol $LAST_TAG $REPO_CHANGELOG_FILE_NAME | grep Version -n | head -n 1 | cut -d : -f 1`))
			LASTLINE=$((`git diff --ignore-space-at-eol $LAST_TAG $REPO_CHANGELOG_FILE_NAME | grep Version -n | tail -n 1 | cut -d : -f 1` - 1))

			LINES=$(( $LASTLINE - $FIRSTLINE ))
			echo Extracting $LINES lines from lines $FIRSTLINE to $LASTLINE
			git diff --ignore-space-at-eol $LAST_TAG $REPO_CHANGELOG_FILE_NAME | head -n $LASTLINE | tail -n $LINES | sed -e "s|^\+\(.*\)|\1|;/^ *$/d" >> $PREPARED_CHANGELOG
			echo >> $PREPARED_CHANGELOG	
			cd ..
		fi
	fi
done

$EDITOR $PREPARED_CHANGELOG

echo -e "\n\n" >> $PREPARED_CHANGELOG

cat $PREPARED_CHANGELOG $OLD_CHANGELOG > $CHANGELOG_FILE_NAME

cd ..