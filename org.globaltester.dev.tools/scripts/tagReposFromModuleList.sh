#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

echo "Tag repositories"

MODULE_LIST="$1"

if [ -z "$MODULE_LIST" ]
then
	echo "Give the path to the modules.list files as first parameter"
	exit 1
fi

cat "$MODULE_LIST" | while read CURRENT_LINE
do
	REPO=`echo "$CURRENT_LINE" | cut -d ' ' -f 1`
	HASH=`echo "$CURRENT_LINE" | cut -d ' ' -f 2`
	VERSION=`echo "$CURRENT_LINE" | cut -d ' ' -f 3`
	DATE=`echo "$CURRENT_LINE" | cut -d ' ' -f 4`

	TAG_MESSAGE="Version bump to $REPO_VERSION"
	TAG_NAME="version/$REPO_VERSION"

	if [ -d "$REPO" ]
	then
		cd "$REPO"
			echo Tagging repo $REPO with \"version/$VERSION\" \(hash: $HASH\)
			git tag -a -m "Released as version $VERSION" "version/$VERSION" "$HASH"
			echo Tagging repo $REPO with \"release/$DATE\" \(version: $VERSION / hash: $HASH\)
			git tag -a -m "Release on $DATE as version $VERSION" "release/$DATE" "$HASH"
		cd ..
	fi
done
