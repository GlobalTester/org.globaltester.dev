#!/bin/bash
# must be called from root directory
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

SKIP=1
CONTINUE=0
ABORT=2

CHANGELOG_FILE_NAME=CHANGELOG
BASH_OPTIONS="-x"
#BASH_OPTIONS=""

function cleanup {
	if [ -e "$RELENG_REPOSITORIES" ]
	then
		rm $RELENG_REPOSITORIES
	fi
}
trap cleanup EXIT

function askUser {
	NEXT_STEP=$1
	read -p "Next step is $NEXT_STEP. Do you want to continue? y/N/s " REMOVE_DIR
			case "$REMOVE_DIR" in
				Yes|yes|Y|y)
					return $CONTINUE
				;;
				Skip|skip|S|s)
					return $SKIP
				;;
				No|no|N|n|""|*)
					exit 1
				;;
			esac
}

while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help") echo -en "Usage:\n\n"
			echo -en "`basename $0`"
			echo -en "This must be called from the root of all checked out HJP repositories."
			exit 1
		;;
		*)
			echo "unknown parameter: $1"
			exit 1;
		;;
	esac
done

# Repo changelog generation

RELENG_REPOSITORIES=`mktemp`

askUser "updating all repository changelogs"
if [ $? -eq $CONTINUE ]
then
	for CURRENT_REPO in */
	do
		CURRENT_REPO=`echo $CURRENT_REPO | sed -e "s|/||"`
		bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/updateRepositoryChangelog.sh $CURRENT_REPO
	done
fi

askUser "commiting the modified repository changelogs"
if [ $? -eq $CONTINUE ]
then
	for CURRENT_REPO in */
	do
		cd $CURRENT_REPO
		if [ -e $CHANGELOG_FILE_NAME ]
		then
			git add $CHANGELOG_FILE_NAME
			git commit -m "Updated the changelog"
		fi
		cd ..
	done
fi

# Build a list of products
echo \# Modify the product list > $RELENG_REPOSITORIES
echo \# Comments and empty lines are ignored >> $RELENG_REPOSITORIES

for CURRENT_REPO in */
do
	CURRENT_REPO=`echo $CURRENT_REPO | sed -e "s|/||"`
	RELENG_CANDIDATE="$CURRENT_REPO/$CURRENT_REPO.releng"
	if [ -e $RELENG_CANDIDATE ]
	then
		echo $CURRENT_REPO >> $RELENG_REPOSITORIES
	fi
done

askUser "modification of product list"
if [ $? -eq $CONTINUE ]
then
	$EDITOR $RELENG_REPOSITORIES
	removeLeadingAndTrailingEmptyLines $RELENG_REPOSITORIES
	removeComments $RELENG_REPOSITORIES
	removeTrailingWhitespace $RELENG_REPOSITORIES
fi

askUser "updating all product changelogs"
if [ $? -eq $CONTINUE ]
then
	for CURRENT_LINE in `cat $RELENG_REPOSITORIES`
	do
		bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/updateProductChangelog.sh "$CURRENT_LINE"
	done
fi

askUser "setting version in relevant files"
if [ $? -eq $CONTINUE ]
then
	for CURRENT_REPO in */
	do
		CURRENT_DATE=`getCurrentDate`
		CURRENT_VERSION=`getCurrentVersionFromChangeLog $CURRENT_REPO/$CHANGELOG_FILE_NAME`
		bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/stampFiles.sh "$CURRENT_REPO" "$CURRENT_VERSION" "$CURRENT_DATE"
		# Apply changes to pom files and dependencies/parents
		mvn org.eclipse.tycho:tycho-versions-plugin:update-pom
	done
fi
# Build/Test

askUser "commiting the modified files"
if [ $? -eq $CONTINUE ]
then
	for CURRENT_REPO in */
	do
		cd $CURRENT_REPO
		if [ -e $CHANGELOG_FILE_NAME ]
		then
			git add .
			git commit -m "Updated the product changelog and all versions"
		fi
		cd ..
	done
fi

askUser "building and testing. This will open a shell for build execution. When all build processes have been executed leave the shell to proceed with the release workflow"
if [ $? -eq $CONTINUE ]
then
	bash $BASH_OPTIONS 
fi

askUser "tagging all versions"
if [ $? -eq $CONTINUE ]
then
	for CURRENT_REPO in */
	do
		bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/tagRepository.sh "$CURRENT_REPO"
	done
fi

askUser "tagging all products"
if [ $? -eq $CONTINUE ]
then
	for CURRENT_LINE in `cat $RELENG_REPOSITORIES`
	do
		bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/tagProduct.sh -r "$CURRENT_LINE"
	done
fi
