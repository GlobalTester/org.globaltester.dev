#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/releng/helper.sh

REPOSITORY=$1
RELENG=$2
TYPE=release
CHANGELOG_FILE_NAME=CHANGELOG

REPO_VERSION=`getCurrentVersionFromChangeLog $REPOSITORY/$CHANGELOG_FILE_NAME`
TAG_MESSAGE="Product version bump to $REPO_VERSION"

REPOS_TO_INCLUDE=`getRepositoriesFromAggregator $REPOSITORY/$RELENG/pom.xml`

for CURRENT_REPO in $REPOS_TO_INCLUDE
do
	echo Tagging: $CURRENT_REPO
	
	cd $CURRENT_REPO

	git tag -a -m "$TAG_MESSAGE" "$TYPE/$REPOSITORY/$REPO_VERSION"

	cd ..
done
