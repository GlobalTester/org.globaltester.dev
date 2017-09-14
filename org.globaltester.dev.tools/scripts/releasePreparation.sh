#!/bin/bash
# must be called from root directory
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

function createProductList {
	if [ -e $PRODUCT_LIST ]
	then
		return
	fi

	echo "Create product list"
	echo -en "" > $PRODUCT_LIST

	for CURRENT_REPO in */
	do
		CURRENT_REPO=`echo $CURRENT_REPO | sed -e "s|/||"`
		RELENG_CANDIDATE="$CURRENT_REPO/$CURRENT_REPO.releng"
		if [ -e $RELENG_CANDIDATE ]
		then
			echo $CURRENT_REPO >> $PRODUCT_LIST
		fi
	done

	echo "Following products will be build:"
	cat  $PRODUCT_LIST

	# generate aggregator POM
	# aggregator header
	echo -e '<?xml version="1.0" encoding="UTF-8"?>' > $AGGREGATOR_POM
	echo -e '<project' >> $AGGREGATOR_POM
	echo -e 'xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"' >> $AGGREGATOR_POM
	echo -e 'xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' >> $AGGREGATOR_POM
	echo -e '  <modelVersion>4.0.0</modelVersion>' >> $AGGREGATOR_POM
	echo -e '  <groupId>com.secunet</groupId>' >> $AGGREGATOR_POM
	echo -e '  <artifactId>com.secunet.releng</artifactId>' >> $AGGREGATOR_POM
	echo -e '  <version>0.0.1</version>' >> $AGGREGATOR_POM
	echo -e '  <packaging>pom</packaging>' >> $AGGREGATOR_POM
	echo -e '  <modules>' >> $AGGREGATOR_POM

	# generate aggregator module list
	MODULELIST=`mktemp`
	for CURRENT_REPO in `cat $PRODUCT_LIST`
	do
		grep "<module>" $CURRENT_REPO/$CURRENT_REPO.releng/pom.xml >> $MODULELIST
	done
	cat $MODULELIST | sed -e 's/.*<module>//; s/<\/module>.*$//' | sort -d -u | sed -e "s/\(.*\)/    <module>\1<\/module>/" >> $AGGREGATOR_POM
	rm $MODULELIST;

	#aggregator footer
	echo -e "  </modules>\n\n</project>" >> $AGGREGATOR_POM


	# derive RepoList from aggregator
	getRepositoriesFromAggregator $AGGREGATOR_POM > $REPO_LIST
}

function commitChanges {
	QUESTION="$1"
	MESSAGE="$2"
	FILES="$3"
	
	read -p "$QUESTION Y/n " INPUT
	case $INPUT in
		"y"|"Y"|"")
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				cd "$CURRENT_REPO"
				git add $FILES
				git commit -m "$MESSAGE"
				cd "$WORKINGDIR"
			done
		;;
	esac
}

# parameter handling
while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help")
			echo -e "Usage:\n"
			echo -e "`basename $0` <options>\n"
			echo -e "This must be called from the root of all checked out secunet repositories."
			echo
			echo "-d | --dir                     the build directory to store information used/generated throughout the process               defaults to a temp file"
			echo
			
			exit 1
		;;
		"-d"|"--dir")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Builddir needs to specify a directory to use!"
				exit 1
			fi
			BUILDDIR=$2
			shift 2
		;;
		*)
			echo "unknown parameter: $1"
			exit 1;
		;;
	esac
done

#create builddir (user interaction)
if [ -z $BUILDDIR ]
then
	DATE_STAMP=`date +%Y%m%d`
	BUILDDIR=`mktemp -d builddir_${DATE_STAMP}_XXX`
fi
BUILDDIR=`getAbsolutePath "$BUILDDIR"`
if [ ! -e "$BUILDDIR" ]
then
	mkdir -p "$BUILDDIR"
fi
echo "Using BUILDDIR in $BUILDDIR"

#set default variables
WORKINGDIR=`pwd`
PRODUCT_LIST=$BUILDDIR/products
REPO_LIST=$BUILDDIR/repos
AGGREGATOR=$BUILDDIR/aggregator
AGGREGATOR_POM=$AGGREGATOR/pom.xml


# create directory structure
mkdir -p "$BUILDDIR/aggregator"
createProductList



function incrementI() {
	((i++))
	if [ $i -eq $NEXT_STEP ]; then
		echo -en "\e[01m"
	else
		echo -en "\e[0m"
	fi
}

# main loop
NEXT_STEP=1
while true; do
	echo -e "\n=============\n"
	echo "Release workflow"
	i=0
	incrementI
	printf "%3d: %s\n" $i "Check open branches";
	incrementI
	printf "%3d: %s\n" $i "Consistency checks";
	incrementI
	printf "%3d: %s\n" $i "Update product changelogs";
	incrementI
	printf "%3d: %s\n" $i "Transfer version numbers";
	incrementI
	printf "%3d: %s\n" $i "Update checksums";
	incrementI

	echo ""
	printf "%3s: %s\n" "q" "quit"
	echo -en "\e[0m"
	printf "%3s: %s\n" "s" "shell"
	echo ""
	PROPOSED_STEP=$NEXT_STEP
	read -p "enter next step ($NEXT_STEP):" INPUT
	NEXT_STEP=${INPUT:-$NEXT_STEP}
	echo -e "\n=============\n"

	case $NEXT_STEP in
		"1")
			echo "Check open branches"

			for CURRENT_REPO in `cat $REPO_LIST`
			do
				cd "$CURRENT_REPO"
					BRANCHES+=`git branch -al --no-merged & echo -e "\n"`
				cd "$WORKINGDIR"
			done

			echo "$BRANCHES" | sort -u

			((NEXT_STEP++))
		;;
		"2")
			echo "Consistency checks"
			
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/performRepositoryConsistencyChecks.sh "$CURRENT_REPO"
			done
			
			echo "Test script checks"
			
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/checkTestScripts.sh "$CURRENT_REPO"
			done
			
			echo "Skipping dependency checks"
			#echo "Dependency checks"
			
			#for CURRENT_REPO in `cat $REPO_LIST`
			#do
			#	bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/checkProjectsForImplicitRequirements.sh "$CURRENT_REPO"
			#done

			((NEXT_STEP++))
		;;
		"3")
			echo "updating all product changelogs"
			PRODUCTCHANGELOGS=()
			for CURRENT_LINE in `cat $PRODUCT_LIST`
			do
				PRODUCTCHANGELOGS+="`getChangeLogFileForRepo $CURRENT_LINE` "
			done
			for CURRENT_LINE in `echo $PRODUCTCHANGELOGS | tr " " "\n" | sort -u`
			do
				$EDITOR `getChangeLogFileForRepo $CURRENT_LINE`
			done

			commitChanges "Commit modified changelogs?" "Update the CHANGELOG" $CHANGELOG_FILE_NAME
			((NEXT_STEP++))
		;;
		"4")
			echo "Transfer version numbers"
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				CURRENT_DATE=`getCurrentDateFromChangeLog $CURRENT_REPO`
				CURRENT_VERSION=`getCurrentVersionFromChangeLog $CURRENT_REPO`
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/stampFiles.sh "$CURRENT_REPO" "$CURRENT_VERSION" "$CURRENT_DATE"
				
				#update versions within POM files
				for CURRENT_PROJECT in $CURRENT_REPO/*/
				do
					if [ ! -e "$CURRENT_PROJECT/pom.xml" ]
					then
						continue;
					fi
					
					echo Updating pom.xml in "$CURRENT_PROJECT"
					
					ARTIFACT_IDS=`xmlstarlet sel -t -v "//artifactId" $CURRENT_PROJECT/pom.xml`
					ARTIFACT_COUNTER=1
					
					#update version for all artifactIds
					for ARTIFACT_ID in $ARTIFACT_IDS
					do
						#update version corresponding to artifactId
							ARTIFACT_VERSION=`getCurrentVersionFromChangeLog $ARTIFACT_ID`
						if [ "$ARTIFACT_VERSION" ]
						then
							ARTIFACT_VERSION=`getCurrentVersionFromChangeLog $ARTIFACT_ID`
							xmlstarlet ed -P --inplace -u "/descendant::artifactId[$ARTIFACT_COUNTER]/parent::node()/version" -v "$ARTIFACT_VERSION-SNAPSHOT" "$CURRENT_PROJECT"/pom.xml
						fi
						((ARTIFACT_COUNTER++))
					done
					
				done
				
			done

			commitChanges "Commit files modified with version numbers?" "Update version numbers" "."
			((NEXT_STEP++))
		;;
		"5")
			echo "Update checksums"
			for CURRENT_PROJECT in `find $(cat $REPO_LIST) -name filelist.a32`
			do
				CURRENT_PROJECT=`dirname $CURRENT_PROJECT`
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/updateChecksums.sh $CURRENT_PROJECT
				if [ $? -ne 0 ]; then
					echo
					echo "Failed to create checksum for $CURRENT_PROJECT"
					echo "Fix the problem and try again"
					((NEXT_STEP--))
					break;
				fi
			done
			commitChanges "Commit updated checksums?" "Update checksums" "."
			((NEXT_STEP++))
		;;
		"q"|"Q"|"quit")
			exit 0
		;;
		"s"|"S"|"shell")
			bash $BASH_OPTIONS
			NEXT_STEP=$PROPOSED_STEP
		;;
		*)
			echo "unknown step, try again"
			continue;
		;;
	esac
done

