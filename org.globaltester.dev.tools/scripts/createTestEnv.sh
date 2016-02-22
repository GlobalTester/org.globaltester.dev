#!/bin/bash

set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

function getRepoFromModule {
	MODULE_NAME="$1"
	if echo "$MODULE_NAME" | grep -E '(\.test|\.ui|\.integrationtest|\.feature|\.site|\.product|\.releng|\.sample|\.ui\.test|\.doc|\.scripts|\.tools|\.ui\.integrationtest)$' >/dev/null
	then
		REPO_NAME=`echo $1 | sed -e "s|\(.*\)\..*|\1|"`
	else
		REPO_NAME="$MODULE_NAME"
	fi
	echo "$REPO_NAME"
}

function commitRepo {
	REPO_NAME="$1"
	MESSAGE="$2"
	
	cd $REPO_NAME
	
	git add .
	
	if [ -z "$MESSAGE" ] 
	then
		MESSAGE=`git diff --cached --name-only`
	fi
	
	if [ -z "$MESSAGE" ] 
	then
		MESSAGE="Empty commit"
	else
		MESSAGE=$'Commited files:\n'"$MESSAGE"
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
	DESTINATION_FILE="$1/$1.releng/pom.xml"
	MODULE_LIST="$2"
	
	echo '<?xml version="1.0" encoding="UTF-8"?>' > "$DESTINATION_FILE"
	echo '<project' >> "$DESTINATION_FILE"
    echo '    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"' >> "$DESTINATION_FILE"
    echo '    xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' >> "$DESTINATION_FILE"
    echo '    <modelVersion>4.0.0</modelVersion>' >> "$DESTINATION_FILE"
    echo '    <groupId>com.hjp.test</groupId>' >> "$DESTINATION_FILE"
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
	DESTINATION_FILE="`getRepoFromModule $MODULE_NAME`/$1/pom.xml"
	echo '<?xml version="1.0" encoding="UTF-8"?>' > "$DESTINATION_FILE"
	echo '<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd" xmlns="http://maven.apache.org/POM/4.0.0"' >> "$DESTINATION_FILE"
	echo '	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' >> "$DESTINATION_FILE"
	echo '  <modelVersion>4.0.0</modelVersion>' >> "$DESTINATION_FILE"
	echo '  <groupId>com.hjp.test</groupId>' >> "$DESTINATION_FILE"
	echo "  <artifactId>$1</artifactId>" >> "$DESTINATION_FILE"
	echo '  <version>0.1.0</version>' >> "$DESTINATION_FILE"
	echo '  <packaging>pom</packaging>' >> "$DESTINATION_FILE"
	echo '</project>' >> "$DESTINATION_FILE"

}

function createProduct {
	PRODUCT_NAME="$1"
	MODULE_LIST="$2"
	
	if [ -z "$MODULE_LIST" ]
	then
		MODULE_LIST="module.1 module.2"
	fi
	
	if [ ! -d $PRODUCT_NAME ]
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
	MODULE_NAME="$1"
	REPO_NAME=`getRepoFromModule $MODULE_NAME`
	
	if [ ! -d $REPO_NAME ]
	then
		createEmptyRepo "$REPO_NAME"
	fi
	mkdir -p "$REPO_NAME/$MODULE_NAME"
	createModulePom "$MODULE_NAME"
}

function prependFile {
	FILE_NAME="$1"
	shift 1
	LINE="$@"
	BAK=`mktemp`
	cat $FILE_NAME > $BAK
	echo "$LINE" > $FILE_NAME
	cat $BAK >> $FILE_NAME
	rm $BAK
}

function addVersionToChangelog {
	MODULE_NAME="$1"
	VERSION="$2"
	DATE="$3"
	
	cd "$MODULE_NAME"

	if [ ! -e $CHANGELOG_FILE_NAME ]
	then
		touch $CHANGELOG_FILE_NAME
	fi

	if [ -z $VERSION ]
	then
		VERSION="0.0.0"
	fi

	if [ -z $DATE ]
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
	REPO_NAME="$1"
	IDENTIFIER="$2"
	VERSION="$3"

    cd "$REPO_NAME"
    git tag -a -m "Tagged version $VERSION of repository $REPO_NAME" "$IDENTIFIER/$VERSION"
    cd ..
}

function tagVersion {
	REPO_NAME="$1"
    VERSION="$2"

	tagRepo "$REPO_NAME" "version" "$VERSION"
}

function tagProduct {
    PRODUCT_NAME="$1"
    VERSION="$2"
	REPO_NAME="$3"

	if [ -z $REPO_NAME ] 
	then
		REPO_NAME="$PRODUCT_NAME"
	fi
	
	tagRepo "$REPO_NAME" "release/$PRODUCT_NAME" "$VERSION"	
}

function addCommit {
	REPO_NAME="$1"
	MESSAGE="$2"
	
	if [ -z "$MESSAGE" ]
	then
		MESSAGE="Dummy commit to produce changes"
	fi
	
	cd "$REPO_NAME"
		git commit -m "$MESSAGE" --allow-empty
	cd ..
}

#product released at 0.1.2, module versioned at 0.1.2
function createDefaultProduct {
	NAME=$1
	createProduct "product.$NAME" "module.$NAME product.$NAME.product"
	commitRepo "product.$NAME"
	commitRepo "module.$NAME"
	addVersionToChangelog "product.$NAME" "0.5.0"
	commitRepo "product.$NAME"
	addVersionToChangelog "module.$NAME" "0.1.2"
	commitRepo "module.$NAME"
	tagVersion "module.$NAME" "0.1.2"
	tagProduct "product.$NAME" "0.1.2"
	tagProduct "product.$NAME" "0.1.2" "module.$NAME"
}

TESTING_DIR=`mktemp -d`

cd $TESTING_DIR

git clone git@git.hjp-consulting.com:org.globaltester.dev

#default product
createDefaultProduct "afterCorrectReleases"

#default product, additionally product released at 0.3.2 and module versioned at 0.2.2,0.3.2
createDefaultProduct "afterMultipleCorrectReleases"
addVersionToChangelog "module.afterMultipleCorrectReleases" "0.2.2"
commitRepo "module.afterMultipleCorrectReleases"
tagVersion "module.afterMultipleCorrectReleases" "0.2.2"
addVersionToChangelog "module.afterMultipleCorrectReleases" "0.3.2"
commitRepo "module.afterMultipleCorrectReleases"
tagVersion "module.afterMultipleCorrectReleases" "0.3.2"
tagProduct "product.afterMultipleCorrectReleases" "0.3.2"
tagProduct "product.afterMultipleCorrectReleases" "0.3.2" "module.afterMultipleCorrectReleases" 

#default product, additional commit in module repo
createDefaultProduct "withNewCommitsSinceRelease"
commitRepo "module.withNewCommitsSinceRelease"

#default product, uncomitted changes in module repository
createDefaultProduct "withUncomittedChanges"
echo stuff > "module.withUncomittedChanges/modified.txt"

#default product, commited change lines in changelog
createDefaultProduct "withCommitedChangelogLines"
prependFile "module.withCommitedChangelogLines/$CHANGELOG_FILE_NAME" "* This line is a commited change in the $CHANGELOG_FILE_NAME
"
commitRepo "module.withCommitedChangelogLines"

#default product, uncommited change lines in changelog
createDefaultProduct "withUncommitedChangelogLines"
prependFile "module.withCommitedChangelogLines/$CHANGELOG_FILE_NAME" "* This line is an uncommited change in the $CHANGELOG_FILE_NAME
"

#default product, uncommited new version in changelog
createDefaultProduct "withUncommitedVersionInChangelog"
addVersionToChangelog "module.withUncommitedVersionInChangelog" "0.2.2"

bash
rm -rf "$TESTING_DIR"