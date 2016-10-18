#!/bin/bash

if [ -z "$DEV_HOME" ]
then
	DEV_HOME=~/dev
fi

if [ -z "$REPOS_FOLDER" ]
then
	REPOS_FOLDER="$DEV_HOME/repos"
fi


if [ -z "$MIRROR_FOLDER" ]
then
	MIRROR_FOLDER="$DEV_HOME/mirror"
fi

if [ -z "$ENVIRONMENTS_FOLDER" ]
then
	ENVIRONMENTS_FOLDER="$DEV_HOME/env"
fi

if [ -z "$IDE_FOLDER" ]
then
	IDE_FOLDER="$DEV_HOME/ide"
fi

ENV_REPOS_FOLDER=repos

GT_MIRROR="$MIRROR_FOLDER/gt"
GT_ARCHIVE_MIRROR="$MIRROR_FOLDER/archive"


alias fordirs="$REPOS_FOLDER/org.globaltester.dev/org.globaltester.dev.tools/scripts/fordirs"
alias forrepos="$REPOS_FOLDER/org.globaltester.dev/org.globaltester.dev.tools/scripts/fordirs -g"

alias cloneall='ssh git@git.globaltester.org | sed -e '\''/^ R/!d'\'' | sed "s/^[ RW\t]*//" | grep "\." | xargs -n 1 -iREPONAME git clone git@git.globaltester.org:REPONAME'
alias cloneallarchive='ssh archive@git.globaltester.org | sed -e '\''/^ R/!d'\'' | sed "s/^[ RW\t]*//" | grep "\." | xargs -n 1 -iREPONAME git clone archive@git.globaltester.org:REPONAME'

alias cloneproduct="$REPOS_FOLDER/org.globaltester.dev/org.globaltester.dev.tools/scripts/checkout.sh -s hjp -i -ni -r"

alias fastmvn="mvn verify -DskipInstall=true -DskipZip=true"

alias mergebasereset="forrepos 'git reset \`git merge-base HEAD origin/master\`'"
alias mergebaselog="forrepos 'git log \`git merge-base HEAD origin/master\`..HEAD'"
alias mergebasediff="forrepos 'git diff \`git merge-base HEAD origin/master\`  HEAD'"

function parallelBuild {
	RESULTS=`mktemp -d`
	echo "Storing results in $RESULTS"
	DIR=`pwd`
	cd "$REPOS_FOLDER/gitolite-admin/testuser/"
	ls | parallel -j 2 -eta --res "$RESULTS" "$REPOS_FOLDER/org.globaltester.dev/org.globaltester.dev.tools/scripts/testBuild.sh -k {} -m \"clean verify -Dhjp.test.driver.port=200{#}\" $@"
	rm "$RESULTS"
	cd "$DIR"
}

function ee {
	ECLIPSE_EXECUTABLE="./eclipse/eclipse"
	if [ -f "$ECLIPSE_EXECUTABLE" ]
	then
		setsid "$ECLIPSE_EXECUTABLE" -data ./workspace >& /dev/null & disown
	else
		echo "No eclipse executable found at $ECLIPSE_EXECUTABLE"
	fi
}

function eee {
	if [ -z "$1" ]
	then
		echo "you need to specify which eclipse to start in first param"
		lsenv
		return
	else
		DIR="$ENVIRONMENTS_FOLDER/$1"
	fi

	if [ ! -d $DIR ]
	then
		echo "$DIR does not exist"
		lsenv
		return
	fi

	cd $DIR
	ee
}

function clonelocal {

	ls "$GT_MIRROR" | parallel "git clone $GT_MIRROR/{}"
	ls | parallel "cd {}; git remote set-url origin git@git.globaltester.org:{}; cd .."
	ls | parallel "cd {}; git remote add local $GT_MIRROR/{}; cd .."

	for REPO in `ls`
	do
		cd "$REPO"
		git pull
		cd ..
	done
}

function mkdevenv {
	CURRENT_DIR=`pwd`
	
	if [ -d "$DEV_HOME" ]
	then
		echo Already existing folder dev, aborting...
		return 1
	fi

	mkdir "$DEV_HOME"
	cd "$DEV_HOME"
	mkdir -p "$ENVIRONMENTS_FOLDER"
	mkdir -p "$IDE_FOLDER"
	mkdir -p "$MIRROR_FOLDER"
	mkdir -p "$REPOS_FOLDER"

	cd "$REPOS_FOLDER"
	git clone git@git.globaltester.org:org.globaltester.dev
	
	cd "$MIRROR_FOLDER"
	
	updatemirrors
	
	cd "$CURRENT_DIR"
}

function mkenv {
	if [ -z $1 ]
	then
		echo "An identifier is needed for dev environment creation"
		return
	fi

	IDENTIFIER="$1"
	WU_PATH="$ENVIRONMENTS_FOLDER/$IDENTIFIER"

	mkdir -p "$WU_PATH"
	mkdir -p "$WU_PATH/$ENV_REPOS_FOLDER"

	cd "$WU_PATH"
}

function mkeclipse {
	if [ -z $1 ]
	then
		echo "An identifier is needed for eclipse dev environment creation"
		return
	fi

	IDENTIFIER="$1"
	WU_PATH="$ENVIRONMENTS_FOLDER/$IDENTIFIER"
	BASE_PATH="$IDE_FOLDER/currentBaseEclipse"

	mkenv "$IDENTIFIER"

	if [ ! -d "$BASE_PATH" ]
	then
		echo "$BASE_PATH does not exist"
		return 1
	fi

	cd "$WU_PATH/$ENV_REPOS_FOLDER"
	clonelocal

	echo Copying eclipse...
	rsync -a "$BASE_PATH/eclipse/" "$WU_PATH/eclipse"

	if [ -d "$BASE_PATH/workspace" ]
	then
		echo Copying workspace...
		rsync -a "$BASE_PATH/workspace/" "$WU_PATH/workspace"
	fi

	if [ -f "$BASE_PATH/modifications.sh" ]
	then
		echo Running modification script...
		"$BASE_PATH/modifications.sh" "$WU_PATH"
	fi

	cd "$WU_PATH"
	echo
	echo "Completed, execute using the following commands"
	echo " from this directory:  ee"
	echo " from anywhere:        eee $IDENTIFIER"
}

function lsenv {
	echo Currently existing environments:
	ls "$ENVIRONMENTS_FOLDER"
}

function gotoenv {
    if [ -z $1 ]
    then
    	echo "An identifier is needed for entering a dev environment"
		lsenv
    	return
    fi
	
	ENV_PATH="$ENVIRONMENTS_FOLDER/$1"

	if [ ! -d "$ENV_PATH" ]
	then
		echo No environment found with this name
		lsenv
		return 1
	fi
	cd "$ENV_PATH"
}

function gotorepos {
    if [ -z $1 ]
    then
        echo "An identifier is needed for entering a dev environments repository directory"
		lsenv
        return
    fi
	
	gotoenv "$1"
	cd "$ENV_REPOS_FOLDER"
}

function updatemirrors {
	CURRENT_DIR=`pwd`

	mkdir -p "$GT_MIRROR"
	cd "$GT_MIRROR"
	cloneall --mirror

	mkdir -p "$GT_ARCHIVE_MIRROR"
	cd "$GT_ARCHIVE_MIRROR"
	cloneallarchive --mirror

	for CURRENT in `find "$MIRROR_FOLDER" -mindepth 2 -maxdepth 2 -type d`
	do
		cd "$CURRENT"
		pwd
		git remote update
	done
	cd "$CURRENT_DIR"
}
