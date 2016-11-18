#!/bin/bash

set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

function getRepoFromModule {
	local MODULE_NAME="$1"
	if echo "$MODULE_NAME" | grep -E '(\.test|\.ui|\.integrationtest|\.feature|\.site|\.product|\.releng|\.sample|\.ui\.test|\.doc|\.scripts|\.tools|\.ui\.integrationtest)$' >/dev/null
	then
		REPO_NAME=`echo $1 | sed -e "s|\(.*\)\..*|\1|"`
	else
		REPO_NAME="$MODULE_NAME"
	fi
	echo "$REPO_NAME"
}

function commitRepo {
	local REPO_NAME="$1"
	local MESSAGE="$2"
	
	cd "$REPO_NAME"
	
	git add .
	
	if [ -z "$MESSAGE" ] 
	then
		MESSAGE=`git diff --cached --name-only`
	fi
	
	if [ -z "$MESSAGE" ] 
	then
		MESSAGE="Empty commit"
	else
		MESSAGE="Commited files:
$MESSAGE"
	fi
	
	git commit -m "$MESSAGE" --allow-empty
	cd ..
}

function createEmptyRepo {
	mkdir "$1"
	cd "$1"
	git init
	cd ..
	commitRepo "$1"
}

function createAggregatorPom {
	local DESTINATION_FILE="$1/$1.releng/pom.xml"
	local MODULE_LIST="$2"
	
	echo '<?xml version="1.0" encoding="UTF-8"?>' > "$DESTINATION_FILE"
	echo '<project' >> "$DESTINATION_FILE"
    echo '    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"' >> "$DESTINATION_FILE"
    echo '    xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' >> "$DESTINATION_FILE"
    echo '    <modelVersion>4.0.0</modelVersion>' >> "$DESTINATION_FILE"
    echo '    <groupId>com.secunet.test</groupId>' >> "$DESTINATION_FILE"
    echo "    <artifactId>$1.releng</artifactId>" >> "$DESTINATION_FILE"
    echo '    <version>0.1.1</version>' >> "$DESTINATION_FILE"
    echo '    <packaging>pom</packaging>' >> "$DESTINATION_FILE"
    echo '    <modules>' >> "$DESTINATION_FILE"
	
	for MODULE in $MODULE_LIST; do
		echo "    <module>../../`getRepoFromModule $MODULE`/$MODULE</module>" >> "$DESTINATION_FILE"
	done;
	
	echo '    </modules>' >> "$DESTINATION_FILE"
	echo '</project>' >> "$DESTINATION_FILE"
}

function createModulePom {
	local DESTINATION_FILE="`getRepoFromModule $MODULE_NAME`/$1/pom.xml"
	echo '<?xml version="1.0" encoding="UTF-8"?>' > "$DESTINATION_FILE"
	echo '<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd" xmlns="http://maven.apache.org/POM/4.0.0"' >> "$DESTINATION_FILE"
	echo '	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' >> "$DESTINATION_FILE"
	echo '  <modelVersion>4.0.0</modelVersion>' >> "$DESTINATION_FILE"
	echo '  <groupId>com.secunet.test</groupId>' >> "$DESTINATION_FILE"
	echo "  <artifactId>$1</artifactId>" >> "$DESTINATION_FILE"
	echo '  <version>0.1.0</version>' >> "$DESTINATION_FILE"
	echo '  <packaging>pom</packaging>' >> "$DESTINATION_FILE"
	echo '</project>' >> "$DESTINATION_FILE"

}

function createProduct {
	local PRODUCT_NAME="$1"
	local MODULE_LIST="$2"
	
	if [ -z "$MODULE_LIST" ]
	then
		MODULE_LIST="module.1 module.2"
	fi
	
	if [ ! -d "$PRODUCT_NAME" ]
	then
		createEmptyRepo "$PRODUCT_NAME"
	fi
	
	mkdir "$PRODUCT_NAME/$PRODUCT_NAME.releng"
	
	for MODULE in $MODULE_LIST; do
		createModule "$MODULE"
	done;
	
	createAggregatorPom "$PRODUCT_NAME" "$MODULE_LIST"
}

function createModule {
	local MODULE_NAME="$1"
	local REPO_NAME=`getRepoFromModule $MODULE_NAME`
	
	if [ ! -d "$REPO_NAME" ]
	then
		createEmptyRepo "$REPO_NAME"
	fi
	mkdir -p "$REPO_NAME/$MODULE_NAME"
	createModulePom "$MODULE_NAME"
}

function prependFile {
	local FILE_NAME="$1"
	shift 1
	local LINE="$@"
	local BAK=`mktemp`
	if [ -e "$FILE_NAME" ]
	then
		cat "$FILE_NAME" > "$BAK"
	fi
	echo "$LINE" > "$FILE_NAME"
	if [ -e "$FILE_NAME" ]
	then
		cat "$BAK" >> "$FILE_NAME"
		rm "$BAK"
	fi
}

function addVersionToChangelog {
	local MODULE_NAME="$1"
	local VERSION="$2"
	local DATE="$3"
	
	cd "$MODULE_NAME"

	if [ ! -e "$CHANGELOG_FILE_NAME" ]
	then
		touch "$CHANGELOG_FILE_NAME"
	fi

	if [ -z "$VERSION" ]
	then
		VERSION="0.0.0"
	fi

	if [ -z "$DATE" ]
	then
		DATE="01.01.2000"
	fi
	
	CONTENT="Version $VERSION ($DATE)

* New version $VERSION of module $MODULE_NAME

"
	
	prependFile "$CHANGELOG_FILE_NAME" "$CONTENT"
	cd ..
}

function tagRepo {
	local REPO_NAME="$1"
	local IDENTIFIER="$2"
	local VERSION="$3"

    cd "$REPO_NAME"
    git tag -a -m "Tagged version $VERSION of repository $REPO_NAME" "$IDENTIFIER/$VERSION"
    cd ..
}

function tagVersion {
	local REPO_NAME="$1"
    local VERSION="$2"

	tagRepo "$REPO_NAME" "version" "$VERSION"
}

function tagProduct {
    local PRODUCT_NAME="$1"
    local VERSION="$2"
	local REPO_NAME="$3"

	if [ -z "$REPO_NAME" ] 
	then
		REPO_NAME="$PRODUCT_NAME"
	fi
	
	tagRepo "$REPO_NAME" "release/$PRODUCT_NAME" "$VERSION"	
}

function addCommit {
	local REPO_NAME="$1"
	local MESSAGE="$2"
	
	if [ -z "$MESSAGE" ]
	then
		MESSAGE="Dummy commit to produce changes"
	fi
	
	cd "$REPO_NAME"
		git commit -m "$MESSAGE" --allow-empty
	cd ..
}

function getDescriptionFileName {
	echo description-$1.txt;
}

function createDefaultProduct {
	local NAME="$1"
	local MODULES="$2"
	local USES_DEFAULT_MODULE=0
	
	if [ -z "$MODULES" ]
	then
		MODULES="module.$NAME"
		USES_DEFAULT_MODULE=1
	fi
	
	
	if [ ! -e `getDescriptionFileName default` ]
	then
		appendDoc "default" "A product that was correctly released at version 0.5.0. The
Product repository is correctly tagged and contains one version."
	fi
	
	appendDoc "$NAME" "This is based on the default product for testing."
	
	
	createProduct "product.$NAME" "product.$NAME.product $MODULES"
	commitRepo "product.$NAME"
	changeAndReleaseModule "product.$NAME" "0.5.0"
	tagProduct "product.$NAME" "0.1.2"
	
	if [ $USES_DEFAULT_MODULE -eq 1 ]
	then	
		appendDoc "$NAME" "This contains the a default module correctly released and tagged at version 0.1.2"
		commitRepo "module.$NAME"
		changeAndReleaseModule "module.$NAME" "0.1.2"
		tagProduct "product.$NAME" "0.1.2" "module.$NAME"
	fi
}

function createOldProduct {
	local NAME="$1"
	
	appendDoc "$NAME" "The product was additionally released at version 0.6.2 and
the module has additional version 0.2.2 and 0.3.2. The 0.3.2
version is part of the 0.6.2 product release"
	createDefaultProduct "$NAME"

	changeAndReleaseModule "module.$NAME" "0.2.2"
	changeAndReleaseModule "module.$NAME" "0.3.2"

	changeAndReleaseModule "product.$NAME" "0.6.2"

	tagProduct "product.$NAME" "0.3.2"
	tagProduct "product.$NAME" "0.3.2" "module.$NAME" 
}

function appendDoc {
	local PRODUCT_NAME=`getDescriptionFileName $1`
	shift 1
	local DESCRIPTION="$@"
	
	if [ ! -e "$PRODUCT_NAME" ] 
	then
		touch "$PRODUCT_NAME"
	fi
	
	echo "$DESCRIPTION" >> "$PRODUCT_NAME"
}

function changeAndReleaseModule {
	local NAME="$1"
	local VERSION="$2"
	addVersionToChangelog "$NAME" "$VERSION"
	commitRepo "$NAME"
	tagVersion "$NAME" "$VERSION"
}

while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help") echo -en "Usage:\n\n"
			echo "`basename $0`
This creates a test environment containing dummy repositories for testing
			
-h | --help         display this help"
			exit 1
		;;
		*)
			echo "unknown parameter: $1"
			exit 1;
		;;
	esac
done


TESTING_DIR=`mktemp -d`

cd "$TESTING_DIR"

git clone git@git.globaltester.org:org.globaltester.dev
#----------------------------
createDefaultProduct "afterCorrectReleases"
appendDoc "afterCorrectReleases" "
Expectation for update repository changelogs:
* skipped
Expectation for update product changelogs:
* skipped
"
#----------------------------
createOldProduct "afterMultipleCorrectReleases"
appendDoc "afterMultipleCorrectReleases" "
Expectation for update repository changelogs:
* skipped

Expectation for update product changelogs:
* skipped
"
#----------------------------
createDefaultProduct "withNewCommitsSinceRelease"
commitRepo "module.withNewCommitsSinceRelease"
appendDoc "withNewCommitsSinceRelease" "The module contains an additional commit which was not yet released

Expectation for update repository changelogs:
* a dummy version
* line as change: This line is a commited change in the $CHANGELOG_FILE_NAME
* one commit for the changelog file
"
#----------------------------
createDefaultProduct "withCommitedChangelogLines"
prependFile "module.withCommitedChangelogLines/$CHANGELOG_FILE_NAME" "* This line is a commited change in the $CHANGELOG_FILE_NAME
"
commitRepo "module.withCommitedChangelogLines"
appendDoc "withCommitedChangelogLines" "The module contains an additional commit containing a new line in the changelog

Expectation for update repository changelogs:
* a dummy version
* line as change: This line is a commited change in the $CHANGELOG_FILE_NAME
* one commit for the changelog file

Expectation for update product changelogs:
* dummy version
* one line for the newly versioned module
"
#----------------------------
createDefaultProduct "withUncommitedChangelogLines"
prependFile "module.withUncommitedChangelogLines/$CHANGELOG_FILE_NAME" "* This line is an uncommited change in the $CHANGELOG_FILE_NAME
"
appendDoc "withUncommitedChangelogLines" "The module contains an uncommitted change lines in its changelog

Expectation for update repository changelogs:
* dummy version
* single line for the version change
Expectation for update product changelogs:
* version from previous module versioning
"
#----------------------------
createDefaultProduct "withUncommitedVersionInChangelog"
addVersionToChangelog "module.withUncommitedVersionInChangelog" "0.2.2"
appendDoc "withUncommitedVersionInChangelog" "The module contains complete new version 0.2.2 in the changelog which has not been committed

Expectation for update repository changelogs:
* version 0.2.2
* single line for the version change
Expectation for update product changelogs:
* version from previous module versioning
"
#----------------------------
createDefaultProduct "multipleVersions" "module.multipleVersions.oneVersion module.multipleVersions.twoVersions module.multipleVersions.threeVersions"
changeAndReleaseModule "module.multipleVersions.oneVersion" "0.1.0"
addCommit "module.multipleVersions.oneVersion"
changeAndReleaseModule "module.multipleVersions.twoVersions" "0.1.0"
changeAndReleaseModule "module.multipleVersions.twoVersions" "0.2.0"
addCommit "module.multipleVersions.twoVersions"
changeAndReleaseModule "module.multipleVersions.threeVersions" "0.1.0"
changeAndReleaseModule "module.multipleVersions.threeVersions" "0.2.0"
changeAndReleaseModule "module.multipleVersions.threeVersions" "0.3.0"
addCommit "module.multipleVersions.threeVersions"
appendDoc "multipleVersions" "The three modules contain multiple version tags and according changelogs

Expectation for update repository changelogs:
* for all three modules the editor contains the dummy version and one dummy commit

Expectation for update product changelogs:
* dummy version
* history for the three modules with size according to module name
"
#----------------------------
createDefaultProduct "withMultipleProductVersions"
changeAndReleaseModule "product.withMultipleProductVersions" "0.6.0"
tagProduct "product.withMultipleProductVersions" "0.2.2"
tagProduct "product.withMultipleProductVersions" "0.2.2" "module.withMultipleProductVersions"
changeAndReleaseModule "product.withMultipleProductVersions" "0.7.0"
tagProduct "product.withMultipleProductVersions" "0.3.2" "module.withMultipleProductVersions"
tagProduct "product.withMultipleProductVersions" "0.3.2"
appendDoc "withMultipleProductVersions" "The product contains 3 released versions in its changelog

Expectation:
* skipped because there are no changes to the last version
Expectation for update product changelogs:
* skipped
"
#----------------------------
createDefaultProduct "withMultipleProductVersionsAndChange"
changeAndReleaseModule "product.withMultipleProductVersionsAndChange" "0.6.0"
tagProduct "product.withMultipleProductVersionsAndChange" "0.2.2"
tagProduct "product.withMultipleProductVersionsAndChange" "0.2.2" "module.withMultipleProductVersionsAndChange"
changeAndReleaseModule "product.withMultipleProductVersionsAndChange" "0.7.0"
tagProduct "product.withMultipleProductVersionsAndChange" "0.3.2" "module.withMultipleProductVersionsAndChange"
tagProduct "product.withMultipleProductVersionsAndChange" "0.3.2"
addCommit "product.withMultipleProductVersionsAndChange"
appendDoc "withMultipleProductVersionsAndChange" "The product contains 3 released versions in its changelog and a change

Expectation:
* dummy version at the top and one commit in the prepared changelog

Expectation for update product changelogs:
* version from previous module versioning
"
#----------------------------

bash
rm -rf "$TESTING_DIR"