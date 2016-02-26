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
	echo "# Modify the product list" >> $PRODUCT_LIST
	echo "# Comments and empty lines are ignored" >> $PRODUCT_LIST

	for CURRENT_REPO in */
	do
		CURRENT_REPO=`echo $CURRENT_REPO | sed -e "s|/||"`
		RELENG_CANDIDATE="$CURRENT_REPO/$CURRENT_REPO.releng"
		if [ -e $RELENG_CANDIDATE ]
		then
			echo $CURRENT_REPO >> $PRODUCT_LIST
		fi
	done

	$EDITOR  $PRODUCT_LIST
	removeLeadingAndTrailingEmptyLines  $PRODUCT_LIST
	removeComments  $PRODUCT_LIST
	removeTrailingWhitespace  $PRODUCT_LIST

	# generate aggregator POM
	# aggregator header
	echo -e '<?xml version="1.0" encoding="UTF-8"?>' > $AGGREGATOR_POM
	echo -e '<project' >> $AGGREGATOR_POM
	echo -e 'xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"' >> $AGGREGATOR_POM
	echo -e 'xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' >> $AGGREGATOR_POM
	echo -e '  <modelVersion>4.0.0</modelVersion>' >> $AGGREGATOR_POM
	echo -e '  <groupId>com.hjp</groupId>' >> $AGGREGATOR_POM
	echo -e '  <artifactId>com.hjp.releng</artifactId>' >> $AGGREGATOR_POM
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

# parameter handling
while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help")
			echo -e "Usage:\n"
			echo -e "`basename $0` <options>\n"
			echo -e "This must be called from the root of all checked out HJP repositories."
			echo
			echo "-d | --dir          the build directory to store information used/generated throughout the process                     defaults to a temp file"

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
	DATE_STAMP=`date +%Y_%m_%d`
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
	printf "%3d: %s\n" $i "Update repository changelogs";
	incrementI
	printf "%3d: %s\n" $i "Update product changelogs";
	incrementI
	printf "%3d: %s\n" $i "Transfer version numbers";
	incrementI
	printf "%3d: %s\n" $i "Update checksums";
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
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/performRepositoryConsistencyChecks.sh $CURRENT_REPO
			done
			
			echo "Dependency checks"
			
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/checkProjectsForImplicitRequirements.sh $CURRENT_REPO
			done

			((NEXT_STEP++))
		;;
		"3")
			echo "Update repository changelogs"
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				CURRENT_REPO=`echo $CURRENT_REPO | sed -e "s|/||"`
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/updateRepositoryChangelog.sh $CURRENT_REPO
			done

			read -p "Commit modified changelogs? Y/n " INPUT
			case $INPUT in
				"y"|"Y"|"")
					for CURRENT_REPO in `cat $REPO_LIST`
					do
						cd "$CURRENT_REPO"
						if [ -e $CHANGELOG_FILE_NAME ]
						then
							git add $CHANGELOG_FILE_NAME
							git commit -m "Updated the changelog"
						fi
						cd "$WORKINGDIR"
					done
				;;
			esac
			((NEXT_STEP++))
		;;
		"4")
			echo "updating all product changelogs"
			for CURRENT_LINE in `cat $PRODUCT_LIST`
			do
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/updateProductChangelog.sh "$CURRENT_LINE"
			done

			read -p "Commit modified changelogs? Y/n " INPUT
			case $INPUT in
				"y"|"Y"|"")
					for CURRENT_REPO in `cat $REPO_LIST`
					do
						cd "$CURRENT_REPO"
						if [ -e $CHANGELOG_FILE_NAME ]
						then
							git add $CHANGELOG_FILE_NAME
							git commit -m "Updated the changelog"
						fi
						cd "$WORKINGDIR"
					done
				;;
			esac
			((NEXT_STEP++))
		;;
		"5")
			echo "Transfer version numbers"
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				if [ ! -e "$CURRENT_REPO/$CHANGELOG_FILE_NAME" ]
				then
					continue;
				fi

				CURRENT_DATE=`getCurrentDateFromChangeLog $CURRENT_REPO/$CHANGELOG_FILE_NAME`
				CURRENT_VERSION=`getCurrentVersionFromChangeLog $CURRENT_REPO/$CHANGELOG_FILE_NAME`
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/stampFiles.sh "$CURRENT_REPO" "$CURRENT_VERSION" "$CURRENT_DATE"
			done
			((NEXT_STEP++))
		;;
		"6")
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
			((NEXT_STEP++))
		;;
		"7")
			echo "Update POM versions"
			cd "$AGGREGATOR"
			mvn org.eclipse.tycho:tycho-versions-plugin:update-pom
			cd "$WORKINGDIR"
			((NEXT_STEP++))
		;;
		"8")
			echo "Build the desired products"
			cd "$AGGREGATOR"
			mvn clean verify -T 2C
			if [ $? -ne 0 ]; then
				echo
				echo "Failed to create build all products"
				echo "Fix the problem and try again"
				((NEXT_STEP--))
			fi
			cd "$WORKINGDIR"
			((NEXT_STEP++))
		;;
		"9")
			echo "Collect build artifacts"
			TARGET="$BUILDDIR/target"
			mkdir "$TARGET"
			find . \( -name *site*.zip -o -name *gt_scripts*.zip -o -name *product-*.zip -o -name *releasetests*.zip \)  -exec cp {} $TARGET \;
			((NEXT_STEP++))
		;;
		"10")
			echo "Generate test documentation"

			# aggregate all releaseTest.md files and generate html
			MDFILE=$BUILDDIR/testDocumentation.md
			echo -n > "$MDFILE"
			for CURRENT_REPO in `getRepositoriesFromAggregator "$AGGREGATOR_POM"`
			do
				find "$CURRENT_REPO" -name releaseTests.md -exec cat {} >> "$MDFILE" \;
			done

			# generate and display printable html
			HTMLFILE="$BUILDDIR/testDocumentation.html"
			markdown "$MDFILE" > "$HTMLFILE"
			echo "open test documentation file $HTMLFILE"
			firefox --new-window "$HTMLFILE"

			((NEXT_STEP++))
		;;
		"11")
			echo "Test the build"
			echo
			echo "All artifacts are generated in $TARGET"
			echo "Install the products and perform the tests described in the test documentation generated in the step before."
			echo
			read -p "press enter when finished" INPUT
			((NEXT_STEP++))
		;;
		"12")
			echo "Generate release documentation"

			# init release documentation file
			MDFILE="$BUILDDIR/releaseDocumentation.md"
			echo -e "Release overview\n================" > "$MDFILE"

			# add environment information
			echo -e "Environment information\n-----------------" >> "$MDFILE"
			echo -e "Date: \`" `date  +%Y-%m-%d` "\`  " >> "$MDFILE"
			echo -e "Executed by: \`" `id -u -n` "\`  " >> "$MDFILE"
			echo -e "Machine: \`" `uname -a` "\`  " >> "$MDFILE"
			echo -e "Java: \`" `java -version 2>&1 | grep build` "\`  " >> "$MDFILE"
			echo -e "Build directory: \`$BUILDDIR\`" >> "$MDFILE"
			echo -e "\n" >> "$MDFILE"

			# add product list
			echo -e "Products released\n-----------------">> "$MDFILE"
			for CURRENT_REPO in `cat $PRODUCT_LIST`
			do
				VERSION=`getCurrentVersionFromChangeLog "$CURRENT_REPO/$CHANGELOG_FILE_NAME"`
				VERSION=`printf "%9s" "@$VERSION" | sed -e 's/ /-/g'`
				HASH=`cd "$CURRENT_REPO"; git log -n1 --format=%H`
				HASH=`printf "%42s" "$HASH" | sed -e 's/ /#/g'`
				printf "\t\t%-75s%9s%s\n" "$CURRENT_REPO" "$VERSION" "$HASH"| sed -e 's/ /-/g' -e 's/@/ /g' -e 's/-/ /' -e 's/#/ /g'>> "$MDFILE"
			done

			# add bundle list
			echo -e "Bundle versions\n-----------------" >> "$MDFILE"
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				if [ ! -e "$CURRENT_REPO/$CHANGELOG_FILE_NAME" ]
				then
					continue;
				fi

				VERSION=`getCurrentVersionFromChangeLog "$CURRENT_REPO/$CHANGELOG_FILE_NAME"`
				VERSION=`printf "%9s" "@$VERSION" | sed -e 's/ /-/g'`
				HASH=`cd $CURRENT_REPO; git log -n1 --format=%H`
				HASH=`printf "%42s" "$HASH" | sed -e 's/ /#/g'`
				printf "\t\t%-75s%9s%s\n" "$CURRENT_REPO" "$VERSION" "$HASH"| sed -e 's/ /-/g' -e 's/@/ /g' -e 's/-/ /' -e 's/#/ /g'>> $MDFILE
			done

			# generate and display printable html
			HTMLFILE="$BUILDDIR/releaseDocumentation.html"
			markdown "$MDFILE" > "$HTMLFILE"
			echo "open release documentation file $HTMLFILE"
			firefox --new-window "$HTMLFILE"


			((NEXT_STEP++))
		;;
		"13")
			echo "Tag repositories"
			for CURRENT_REPO in `cat $REPO_LIST`
			do
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/tagRepository.sh "$CURRENT_REPO"
			done
			((NEXT_STEP++))
		;;
		"14")
			echo "Tag products"
			for CURRENT_LINE in `cat $PRODUCT_LIST`
			do
				bash $BASH_OPTIONS org.globaltester.dev/org.globaltester.dev.tools/scripts/tagProduct.sh -r "$CURRENT_LINE"
			done
			((NEXT_STEP++))
		;;
		"15")
			echo "Publish release"
			echo
			echo "Congratulations! You just created a complete release."
			echo
			echo "Now you need to publish the results."
			echo "Final artifacts are located in $TARGET"
			echo
			echo "This step is not yet supported by the workflow script but should include:"
			echo "* pushing release commits and tags to relevant repos (HJP servers, GitHub)"
			echo "* uploading the release to website"
			echo "* informing customers about the new version (the CHANGELOG files are a great basis for this)"
			echo
			read -p "press enter when finished" INPUT
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

