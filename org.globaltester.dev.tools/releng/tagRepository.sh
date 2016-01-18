#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/releng/helper.sh

REPOSITORY=$1

REPO_VERSION=`getCurrentVersionFromChangeLog $REPOSITORY/$CHANGELOG_FILE_NAME`
TAG_MESSAGE="Version bump to $REPO_VERSION"

if [ ! -e "$REPOSITORY/$CHANGELOG_FILE_NAME" ]
then
	echo Did not tag repository due to missing changelog file
	return
fi

cd $REPOSITORY

git tag -a -m "$TAG_MESSAGE" "version/$REPO_VERSION"

cd ..