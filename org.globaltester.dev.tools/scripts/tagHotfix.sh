#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

REPOSITORY=$1
HOTFIX=$2

REPO_VERSION=`getCurrentVersionFromChangeLog $REPOSITORY/$CHANGELOG_FILE_NAME`
TAG_MESSAGE="Tag Hotfix version $HOTFIX"

cd $REPOSITORY

git tag -a -m "$TAG_MESSAGE" "hotfix/$HOTFIX"

cd ..
