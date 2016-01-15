#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/releng/helper.sh

REPOSITORY=$1
CHANGELOG_FILE_NAME=CHANGELOG

REPO_VERSION=`getCurrentVersionFromChangeLog $REPOSITORY/$CHANGELOG_FILE_NAME`
TAG_MESSAGE="Version bump to $REPO_VERSION"

cd $REPOSITORY

git tag -a -m "$TAG_MESSAGE" "version/$REPO_VERSION"

cd ..