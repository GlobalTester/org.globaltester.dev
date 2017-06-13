#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

PARAMETER_NUMBER=0
REPOSITORY=org.globaltester.platform
FOLDER=$REPOSITORY.releng
TYPE=release
CHANGELOG_FILE_NAME=CHANGELOG

while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help") echo -en "Usage (to be called from from root directory of all repos):\n\n"
			echo -en "`basename $0` <options>\n\n"
			echo "-v | --version      override version                                         defaults to version read from $CHANGELOG_FILE_NAME"
			echo "-t | --type         set type to be used"
			echo "                     possible values are \"release\" and \"hotfix\"          defaults to $TYPE"
			echo "-r | --repo         sets the repository name for the build                   defaults to $REPOSITORY"
			echo "                     Setting this as the first parameter also sets folder"
			echo "                     to <value>.releng"
			echo "-f | --folder       sets the project folder name for the build               defaults to $FOLDER"
			echo "-h | --help         display this help"
			exit 1
		;;
		"-v"|"--version")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Version parameter needs a value to use!"
				exit 1
			fi
			VERSION=$2
			shift 2
		;;
		"-t"|"--type")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Version parameter needs a value to use!"
				exit 1
			fi
			TYPE=$2
			shift 2
		;;
		"-f"|"--folder")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Folder parameter needs a folder to use!"
				exit 1
			fi
			FOLDER=$2
			shift 2
		;;
		"-r"|"--repo")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Repository parameter needs a folder to use!"
				exit 1
			fi
			REPOSITORY=$2
			if [ $PARAMETER_NUMBER -eq 0 ]
			then
				FOLDER="$REPOSITORY.releng"
			fi
			shift 2
		;;
	esac
	
	PARAMETER_NUMBER=$(( $PARAMETER_NUMBER + 1 ))
done


if [ ! -e "$REPOSITORY/$FOLDER/pom.xml" ]
then
	echo Did not tag product $REPOSITORY due to missing releng file
	exit
fi

case "$TYPE" in
	"hotfix")
		TAG_MESSAGE="Hotfix release for ticket #$VERSION"
		TAG_NAME="$TYPE/$VERSION"
	;;
	"release")
		if [ -z "$VERSION" ]
		then
			VERSION=`getCurrentVersionFromChangeLog $REPOSITORY`
		fi
		
		if [ -z "$VERSION" ]
		then
			echo Could not tag product $REPOSITORY due to missing version information
			exit
		fi
	
		TAG_MESSAGE="Product version bump to $VERSION"
		TAG_NAME="$TYPE/$REPOSITORY/$VERSION"
	;;
	*)
		echo "ERROR: Type unknown"
		exit 1
	;;
esac

if [ -z "$VERSION" ]
then
	echo "ERROR: No version set";
	exit 1
fi

if [ -z "$TAG_MESSAGE" ]
then
	echo "ERROR: No tag message was set";
	exit 1
fi

if [ -z "$TAG_NAME" ]
then
	echo "ERROR: No tag name was set";
	exit 1
fi

REPOS_TO_INCLUDE=`getRepositoriesFromAggregator $REPOSITORY/$FOLDER/pom.xml`

for CURRENT_REPO in $REPOS_TO_INCLUDE
do
	echo Tagging: $CURRENT_REPO
	
	cd $CURRENT_REPO

	git tag -a -m "$TAG_MESSAGE" "$TAG_NAME"

	cd ..
done
