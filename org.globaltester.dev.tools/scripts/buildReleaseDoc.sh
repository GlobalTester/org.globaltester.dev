#!/bin/bash


TARGET="$2"
cd "$1"

. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

function createProductList {

	echo "Create product list"
	echo -en "" > $PRODUCT_LIST

	for CURRENT_REPO in */
	do
		CURRENT_REPO=`echo "$CURRENT_REPO" | sed -e "s|/||"`
		RELENG_CANDIDATE="$CURRENT_REPO/$CURRENT_REPO.releng"
		if [ -e "$RELENG_CANDIDATE" ]
		then
			echo "$CURRENT_REPO" >> "$PRODUCT_LIST"
		fi
	done

	TEMP_LIST=`mktemp`
	for CURRENT_REPO in `cat "$PRODUCT_LIST"`
	do
		grep "<module>" "$CURRENT_REPO/$CURRENT_REPO.releng/pom.xml" >> "$TEMP_LIST"
	done
	
	cat "$TEMP_LIST" | sed -e 's/.*<module>//; s/<\/module>.*$//' | sort -d -u | sed -e "s/\(.*\)/    <module>\1<\/module>/" > "$MODULE_LIST"
	rm "$TEMP_LIST"

	# derive RepoList from aggregator
	getRepositoriesFromModules "$MODULE_LIST" > "$REPO_LIST"
}


#set default variables
WORKINGDIR=`pwd`
PRODUCT_LIST=`mktemp`
REPO_LIST=`mktemp`
MODULE_LIST=`mktemp`

createProductList

echo "Generate test documentation into $TARGET"

# aggregate all releaseTest.md files and generate html
MDFILE="$TARGET/TestDocumentation.md"
echo -n > "$MDFILE"
for CURRENT_REPO in `cat $REPO_LIST`
do
	find "$CURRENT_REPO" -name releaseTests.md -exec cat {} >> "$MDFILE" \;
done

echo "Generate release documentation into $TARGET"

# init release documentation file
MDFILE="$TARGET/ReleaseDocumentation.md"
echo -e "Release overview\n================" > "$MDFILE"

# add environment information
echo -e "Environment information\n-----------------" >> "$MDFILE"
echo -e "Date: \`" `date  +%Y-%m-%d` "\`  " >> "$MDFILE"
echo -e "Executed by: \`" `id -u -n` "\`  " >> "$MDFILE"
echo -e "Machine: \`" `uname -a` "\`  " >> "$MDFILE"
echo -e "Java: \`" `java -version 2>&1 | grep build` "\`  " >> "$MDFILE"
echo -e "\n" >> "$MDFILE"

# add product list
echo -e "Products released\n-----------------">> "$MDFILE"
for CURRENT_REPO in `cat $PRODUCT_LIST`
do
	VERSION=`getCurrentVersionFromChangeLog "$CURRENT_REPO"`
	VERSION=`printf "%9s" "@$VERSION" | sed -e 's/ /-/g'`
	HASH=`cd "$CURRENT_REPO"; git log -n1 --format=%H`
	HASH=`printf "%42s" "$HASH" | sed -e 's/ /#/g'`
	printf "\t\t%-75s%9s%s\n" "$CURRENT_REPO" "$VERSION" "$HASH"| sed -e 's/ /-/g' -e 's/@/ /g' -e 's/-/ /' -e 's/#/ /g'>> "$MDFILE"
done

# add bundle list
echo -e "Bundle versions\n-----------------" >> "$MDFILE"
for CURRENT_REPO in `cat $REPO_LIST`
do
	VERSION=`getCurrentVersionFromChangeLog "$CURRENT_REPO"`
	VERSION=`printf "%9s" "@$VERSION" | sed -e 's/ /-/g'`
	HASH=`cd $CURRENT_REPO; git log -n1 --format=%H`
	HASH=`printf "%42s" "$HASH" | sed -e 's/ /#/g'`
	printf "\t\t%-75s%9s%s\n" "$CURRENT_REPO" "$VERSION" "$HASH"| sed -e 's/ /-/g' -e 's/@/ /g' -e 's/-/ /' -e 's/#/ /g'>> $MDFILE
done

