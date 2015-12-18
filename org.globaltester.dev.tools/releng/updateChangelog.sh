#!/bin/sh
# must be called from root directory for all repos

CHANGELOG_FILE_NAME="CHANGELOG"
REPOSITORY=$1

#TODO find last version tagged state of the repository
LAST_TAGGED_COMMIT_RANGE=b12f5df..

function cleanup {
	if [ ! -z "$TEMPFILE" ]
	then
		rm $TEMPFILE
	fi
}

trap cleanup EXIT

PREPARED_CHANGELOG=`mktemp`
OLD_CHANGELOG=`mktemp`


cd $REPOSITORY

if [ -e $CHANGELOG_FILE_NAME ]
then
	cat $CHANGELOG_FILE_NAME > $OLD_CHANGELOG
fi

echo -e "Version x.y.z (`date +%d.%m.%Y`)\n" > $PREPARED_CHANGELOG
git log --oneline $LAST_TAGGED_COMMIT_RANGE | sed -e 's|[A-Fa-f0-9]*\s\(.*\)|\* \1|' >> $PREPARED_CHANGELOG

$EDITOR $PREPARED_CHANGELOG

echo -e "\n\n" >> $PREPARED_CHANGELOG

cat $PREPARED_CHANGELOG $OLD_CHANGELOG > $CHANGELOG_FILE_NAME

cd ..