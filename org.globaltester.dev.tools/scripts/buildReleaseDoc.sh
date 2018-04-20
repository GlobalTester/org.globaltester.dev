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

DATE=`date +%Y%m%d`

createProductList

echo "Generate test documentation into $TARGET"

MDFILE="$TARGET/TestDocumentation.md"
MODULES_LIST_FILE="$TARGET/modules.list"
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
echo -e "Date: \` $DATE \`  " >> "$MDFILE"
echo -e "Executed by: \`" `id -u -n` "\`  " >> "$MDFILE"
echo -e "Machine: \`" `uname -a` "\`  " >> "$MDFILE"
echo -e "Java: \`" `java -version 2>&1 | grep build` "\`  " >> "$MDFILE"
echo -e "\n" >> "$MDFILE"

# add product list
echo -e "Products released\n-----------------">> "$MDFILE"
for CURRENT_REPO in `cat $PRODUCT_LIST`
do
	VERSION=`getCurrentVersionFromChangeLog "$CURRENT_REPO"`
	VERSION=`printf "%9s" "$VERSION" | sed -e 's/ /-/g'`
	HASH=`cd "$CURRENT_REPO"; git log -n1 --format=%H`
	HASH=`printf "%42s" "$HASH" | sed -e 's/ /#/g'`
	printf "\t\t%-75s%9s%s\n" "$CURRENT_REPO" "$VERSION" "$HASH"| sed -e 's/ /-/g' -e 's/@/ /g' -e 's/-/ /' -e 's/#/ /g'>> "$MDFILE"
done

# add bundle list
echo -e "Bundle versions\n-----------------" >> "$MDFILE"
for CURRENT_REPO in `cat $REPO_LIST`
do
	VERSION_CLEAN=`getCurrentVersionFromChangeLog "$CURRENT_REPO"`
	VERSION=`printf "%9s" "$VERSION_CLEAN" | sed -e 's/ /-/g'`
	HASH_CLEAN=`cd "$CURRENT_REPO"; git log -n1 --format=%H`
	HASH=`printf "%42s" "$HASH_CLEAN" | sed -e 's/ /#/g'`
	printf "\t\t%-75s%9s%s\n" "$CURRENT_REPO" "$VERSION" "$HASH"| sed -e 's/ /-/g' -e 's/@/ /g' -e 's/-/ /' -e 's/#/ /g'>> "$MDFILE"
	echo "$CURRENT_REPO $HASH_CLEAN $VERSION_CLEAN $DATE" >> "$MODULES_LIST_FILE"
done


# add release preparation checklist
echo -e "<p style=\"page-break-after: always\"/>" >> "$MDFILE"
echo -e "" >> "$MDFILE"
echo -e "Release preparation checklist\n-----------------" >> "$MDFILE"
echo -e "- [ ] Check open issues" >> "$MDFILE"
echo -e "- [ ] Check Sonar quality gate" >> "$MDFILE"
echo -e "- [ ] Check open branches" >> "$MDFILE"
echo -e "- [ ] Perform consistency checks" >> "$MDFILE"
echo -e "- [ ] Update changelogs" >> "$MDFILE"
echo -e "- [ ] Update Whats's new (if needed)" >> "$MDFILE"
echo -e "- [ ] Generate new test data for terminal tests" >> "$MDFILE"
echo -e "- [ ] Update CfgDflt*.java classes" >> "$MDFILE"
echo -e "- [ ] Transfer version numbers" >> "$MDFILE"
echo -e "- [ ] Update checksums" >> "$MDFILE"
echo -e "- [ ] Push required changes to master and go to sleep" >> "$MDFILE"

# add release finalisation checklist
echo -e "<p style=\"page-break-after: always\"/>" >> "$MDFILE"
echo -e "" >> "$MDFILE"
echo -e "Release finalisation checklist\n-----------------" >> "$MDFILE"
echo -e "- [ ] Perform release tests on final artifacts" >> "$MDFILE"
echo -e "- [ ] Follow up on release test results (e.g. documentation changes, creation of issues and hotfixes)" >> "$MDFILE"
echo -e "- [ ] Tag products" >> "$MDFILE"
echo -e "- [ ] Push master/tags to repositories (bitbucket, gitolite, GitHub)" >> "$MDFILE"
echo -e "- [ ] Upload artifacts to website" >> "$MDFILE"
echo -e "- [ ] Inform customers about the new version (the CHANGELOG files are a great basis for this)" >> "$MDFILE"
echo -e "- [ ] Celebrate" >> "$MDFILE"

