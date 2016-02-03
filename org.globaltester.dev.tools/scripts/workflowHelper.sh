#!/bin/bash
# must be called from root directory
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

SKIP=1
CONTINUE=0
ABORT=2

CHANGELOG_FILE_NAME=CHANGELOG

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

# parameter handling
while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help") 
			echo -e "Usage:\n"
			echo -e "`basename $0`\n"
			echo -e "This must be called from the root of all checked out HJP repositories."
			exit 1
		;;
		*)
			echo "unknown parameter: $1"
			exit 1;
		;;
	esac
done

# build product list
RELENG_REPOSITORIES=`mktemp`
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
	printf "%3d: %s\n" $i "Update repository changelogs";
	incrementI
	printf "%3d: %s\n" $i "Check product list";
	incrementI
	printf "%3d: %s\n" $i "Update product changelogs";
	incrementI
	printf "%3d: %s\n" $i "Transfer version numbers";
	incrementI
	printf "%3d: %s\n" $i "Update checksums";
	incrementI
	printf "%3d: %s\n" $i "Create consolidated aggregator build";
	incrementI
	printf "%3d: %s\n" $i "Update POM versions";
	incrementI
	printf "%3d: %s\n" $i "Build the desired products";
	incrementI
	printf "%3d: %s\n" $i "Collect build artifacts";
	incrementI
	printf "%3d: %s\n" $i "Generate test documentation";
	incrementI
	printf "%3d: %s\n" $i "Test the build";
	incrementI
	printf "%3d: %s\n" $i "Generate release documentation";
	incrementI
	printf "%3d: %s\n" $i "Tag repositories";
	incrementI
	printf "%3d: %s\n" $i "Tag products";
	incrementI
	printf "%3d: %s\n" $i "Publish release";
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
			bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/checkOpenBranches.sh
			((NEXT_STEP++))
		;;
		"2") 
			echo "Consistency checks"
			echo "--none implemented yet--"

			((NEXT_STEP++))
		;;
		"3") 
			echo "Update repository changelogs"
			for CURRENT_REPO in */; do
				CURRENT_REPO=`echo $CURRENT_REPO | sed -e "s|/||"`
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/updateRepositoryChangelog.sh $CURRENT_REPO
			done

			read -p "Commit modified changelogs? Y/n " INPUT
			case $INPUT in
				"y"|"Y"|"")
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
				;;
			esac
			((NEXT_STEP++))
		;;
		"4") 
			echo "Check product list"
			$EDITOR $RELENG_REPOSITORIES
			removeLeadingAndTrailingEmptyLines $RELENG_REPOSITORIES
			removeComments $RELENG_REPOSITORIES
			removeTrailingWhitespace $RELENG_REPOSITORIES
			((NEXT_STEP++))
		;;
		"5") 
			echo "updating all product changelogs"
			for CURRENT_LINE in `cat $RELENG_REPOSITORIES`;	do
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/updateProductChangelog.sh "$CURRENT_LINE"
			done

			read -p "Commit modified changelogs? Y/n " INPUT
			case $INPUT in
				"y"|"Y"|"")
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
				;;
			esac
			((NEXT_STEP++))
		;;
		"6") 
			echo "Transfer version numbers"
			for CURRENT_REPO in */
			do
				CURRENT_DATE=`getCurrentDateFromChangeLog $CURRENT_REPO/$CHANGELOG_FILE_NAME`
				CURRENT_VERSION=`getCurrentVersionFromChangeLog $CURRENT_REPO/$CHANGELOG_FILE_NAME`
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/stampFiles.sh "$CURRENT_REPO" "$CURRENT_VERSION" "$CURRENT_DATE"
			done
			((NEXT_STEP++))
		;;
		"7")
			echo "Update checksums"
			for CURRENT_PROJECT in `find . -name filelist.a32`
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
			((NEXT_STEP++))
		;;
		"8")
			echo "Create consolidated aggregator build"
			DATE_STAMP=`date +%Y_%m_%d`
			BUILDDIR=`mktemp -d builddir_${DATE_STAMP}_XXX`
			echo "Created BUILDDIR in $BUILDDIR"

			#aggregator header
			mkdir $BUILDDIR/aggregator
			POM=$BUILDDIR/aggregator/pom.xml
			echo -e '<?xml version="1.0" encoding="UTF-8"?>' > $POM
			echo -e '<project' > $POM
			echo -e 'xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"' >> $POM
			echo -e 'xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' >> $POM
			echo -e '  <modelVersion>4.0.0</modelVersion>' >> $POM
			echo -e '  <groupId>com.hjp</groupId>' >> $POM
			echo -e '  <artifactId>com.hjp.releng</artifactId>' >> $POM
			echo -e '  <version>0.0.1</version>' >> $POM
			echo -e '  <packaging>pom</packaging>' >> $POM
			echo -e '  <modules>' >> $POM

			#generate aggregator module list
			MODULELIST=`mktemp`
			for CURRENT_REPO in `cat $RELENG_REPOSITORIES`
			do
				grep "<module>" $CURRENT_REPO/$CURRENT_REPO.releng/pom.xml >> $MODULELIST
			done
			cat $MODULELIST | sed -e 's/.*<module>//; s/<\/module>.*$//' | sort -d -u | sed -e "s/\(.*\)/    <module>\1<\/module>/" >> $POM
			rm $MODULELIST;

			#aggregator footer
			echo -e "  </modules>\n\n</project>" >> $POM


			((NEXT_STEP++))
		;;
		"9")
			echo "Update POM versions"
	#	mvn org.eclipse.tycho:tycho-versions-plugin:update-pom
			((NEXT_STEP++))
		;;
		"10")
			echo "Build the desired products"
			((NEXT_STEP++))
		;;
		"11")
			echo "Collect build artifacts"
			((NEXT_STEP++))
		;;
		"12")
			echo "Generate test documentation"
			((NEXT_STEP++))
		;;
		"13")
			echo "Test the build"
			((NEXT_STEP++))
		;;
		"14")
			echo "Generate release documentation"
			((NEXT_STEP++))
		;;
		"15")
			echo "Tag repositories"
			((NEXT_STEP++))
		;;
		"16")
			echo "Tag products"
			((NEXT_STEP++))
		;;
		"17")
			echo "Publish release"
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














# Repo changelog generation





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
