#!/bin/bash

if [ -z "$DEV_HOME" ]
then
	DEV_HOME=~/dev
fi

if [ -z "$REPOS_FOLDER" ]
then
	REPOS_FOLDER="$DEV_HOME/repos"
fi


if [ -z "$ORIGIN_SOURCE" ]
then
	ORIGIN_SOURCE="ssh://git@bitbucket.secunet.de:7999/gt/"
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

if [ -z "PARALLEL_BUILD_PARAMS" ]
then
	PARALLEL_BUILD_PARAMS=
fi

ENV_REPOS_FOLDER=repos

GT_MIRROR="$MIRROR_FOLDER/gt"
GT_ARCHIVE_MIRROR="$MIRROR_FOLDER/archive"

XEPHYR_GENERAL_DISP=:20
XEPHYR_LOCK_FILE=/tmp/XephyrGeneral.lock
XEPHYR_GENERAL_PID=

alias fordirs="$REPOS_FOLDER/org.globaltester.dev/org.globaltester.dev.tools/scripts/fordirs"
alias forrepos="$REPOS_FOLDER/org.globaltester.dev/org.globaltester.dev.tools/scripts/fordirs -g"

alias cloneproduct="$REPOS_FOLDER/org.globaltester.dev/org.globaltester.dev.tools/scripts/checkout.sh -s $ORIGIN_SOURCE -i -ni -r"

alias cloneall='cloneproduct com.secunet.globaltester.universe'

alias fastmvn="mvn verify --offline -DskipInstall=true -DskipZip=true"

alias mergebasereset="forrepos 'git reset \`git merge-base HEAD origin/master\`'"
alias mergebaselog="forrepos 'git log \`git merge-base HEAD origin/master\`..HEAD'"

alias getArtifacts='bash -c "if [ -d results ]; then echo \"results dir exists, aborting\"; exit; fi; mkdir results; find . \( -name *site*.zip -o -name *deploy*.zip -o -name *gt_scripts*.zip -o -name *product-*.zip \) -exec cp {} results/ \;"'

function file2hex {
	if [ -f "$1" ]
	then
		echo `xxd -p "$1"` | sed -e "s|\s||g" | tr '[:lower:]' '[:upper:]'
	else
		echo "Usage: file2hex <filename>"
	fi
}

function hex2file {
	if [ -z "$1" -o -z "$2" ]
	then
		echo "Usage: hex2file <hexstring> <filename>"
	else
		rm -f "$2"
		echo "$1" | xxd -r -p - "$2" | sed -e "s|\s||g"
	fi
}

function inXephyr {
	COMMANDSTRING="";
	
	for CURRENT in "$@"
	do
		COMMANDSTRING="$COMMANDSTRING\"`printf %q "$CURRENT"`\" "
	done
	 
	if [ ! -f "$XEPHYR_LOCK_FILE" ]
	then
		setsid bash -c "touch $XEPHYR_LOCK_FILE; Xephyr $XEPHYR_GENERAL_DISP; rm $XEPHYR_LOCK_FILE" & disown
		sleep 1
		DISPLAY="$XEPHYR_GENERAL_DISP" setsid x-window-manager & disown
	fi
	sleep 1
	DISPLAY="$XEPHYR_GENERAL_DISP" bash -i -c "$COMMANDSTRING"
}

function mergebasediff {
	forrepos 'git diff --color '"$@"' `git merge-base HEAD origin/master`  HEAD' | less -F -r
}

function parallelBuild {

	BRANCH=$1

	if [ -z $BRANCH ]
	then
		BRANCH=master
	fi

	SOURCE=$2

	if [ -z $SOURCE ]
	then
		SOURCE=$GT_MIRROR/
	fi

	RESULTS=`mktemp -d`
	echo "Storing results in $RESULTS"

	XEPHYR_PID=
	ORIG_DISPLAY=$DISPLAY

	which Xephyr
	if [ 0 -eq `which Xephyr > /dev/null; echo $?` ]
	then
		DISPLAY_XEPHYR=:10
		Xephyr $DISPLAY_XEPHYR &
		XEPHYR_PID=$!
		DISPLAY=$DISPLAY_XEPHYR
		if [ 0 -eq $? ]
		then
			sleep 1
			x-window-manager &
		fi
	fi

	DIR=`pwd`
	cd "$REPOS_FOLDER/gitolite-admin/testuser/"

	echo -e "com.secunet.globaltester.universe
com.secunet.globaltester.prove.eidclient
com.secunet.globaltester.prove.epa
com.secunet.globaltester.prove.epa.poseidas
com.secunet.globaltester.prove.epareader
com.secunet.globaltester.prove.epp
com.secunet.globaltester.prove.is
com.secunet.persosim.profiletool
com.secunet.poseidas
de.persosim.rcp
org.globaltester.platform" | nice parallel $PARALLEL_BUILD_PARAMS --progress --files --res "$RESULTS" "$REPOS_FOLDER/org.globaltester.dev/org.globaltester.dev.tools/scripts/testBuild.sh --repo {} -- --source $SOURCE --branch $BRANCH --non-interactive"

	echo Build results:
	grep -R -e "BUILD" $RESULTS
	echo Failed during dependency resolution:
	grep -R -e "not successful" $RESULTS;

	cd "$DIR"
}

function watchBuild {
	DIR=$1
	NAME=pbuild
	screen -S $NAME -m -d

	screen -S $NAME -X defscrollback 50000

	screen -S $NAME -X exec /bin/bash -c "while true; do clear; echo Build results:; grep -R -e \"BUILD\" $DIR; echo Failed during dependency resolution:; grep -R -e \"not successful\" $DIR; sleep 2; done;"
	screen -S $NAME -X title "Build overview"

	for CURRENT in `ls $DIR`
	do
		for JOB in `ls $DIR/$CURRENT`
		do
			screen -S $NAME -X screen
			screen -S $NAME -X title "$CURRENT/$JOB standard out"
			screen -S $NAME -X exec /bin/bash -c "while true; do tail -fn +1 $DIR/$CURRENT/$JOB/stdout; sleep 2; done;"
			screen -S $NAME -X screen
			screen -S $NAME -X title "$CURRENT/$JOB standard err"
			screen -S $NAME -X exec /bin/bash -c "while true; do tail -fn +1 $DIR/$CURRENT/$JOB/stderr; sleep 2; done;"
		done
	done

	screen -S $NAME -X select 0
	screen -r $NAME	
}

function ee {
	ECLIPSE_EXECUTABLE="./eclipse/eclipse"

	CURRENT_DIR="`pwd`"
	while [ ! "`pwd`" = "/" ]
	do
		if [ -f "$ECLIPSE_EXECUTABLE" ]
		then
			setsid "$ECLIPSE_EXECUTABLE" -data ./workspace "$@" >& /dev/null & disown
			cd "$CURRENT_DIR"
			return
		fi
		cd ..
	done
	echo "No eclipse executable found at $ECLIPSE_EXECUTABLE in this or parent directories"
	cd "$CURRENT_DIR"
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

	shift

	if [ ! -d $DIR ]
	then
		echo "$DIR does not exist"
		lsenv
		return
	fi

	cd $DIR
	ee "$@"
}

_existing_envs()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    COMPREPLY=( $(compgen -W "$( command ls ~/dev/env/ )" -- ${cur}) )
}

complete -F _existing_envs eee
complete -F _existing_envs gotorepos
complete -F _existing_envs gotoenv
complete -F _existing_envs mkeclipse
complete -F _existing_envs mkgtenv
complete -F _existing_envs mkenv


function eeee {
	eee $1
	exit
}

function clonelocal {

	ls "$GT_MIRROR" | parallel "git clone $GT_MIRROR/{}"
	ls | parallel "cd {}; git remote set-url origin ssh://git@bitbucket.secunet.de:7999/gt/{}; cd .."
	ls | parallel "cd {}; git remote add bitbucket ssh://git@bitbucket.secunet.de:7999/gt/{}; cd .."
	ls | parallel "cd {}; git remote add gitolite ssh://git@globaltester-git.secunet.com:2021/{}; cd .."
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
	git clone ${ORIGIN_SOURCE}org.globaltester.dev
	
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

	_createenv "$1"

	cd "$WU_PATH"
}

function _createenv {
	IDENTIFIER="$1"
	WU_PATH="$ENVIRONMENTS_FOLDER/$IDENTIFIER"

	mkdir -p "$WU_PATH"
	mkdir -p "$WU_PATH/$ENV_REPOS_FOLDER"
	
}

function _copyfolder {
	IDENTIFIER="$1"
	SOURCE_FOLDER="$2"
	TARGET_NAME="$3"
	WU_PATH="$ENVIRONMENTS_FOLDER/$IDENTIFIER"

	echo "Copying $TARGET_NAME..."

	if [ ! -d "$SOURCE_FOLDER" ]
	then
		echo "$SOURCE_FOLDER does not exist"
		return 1
	fi

	rsync -a "$SOURCE_FOLDER/" "$WU_PATH/$TARGET_NAME"
}

function _copyeclipse {
	BASE_LINK="currentBaseEclipse"

	if [ -n "$2" ]
	then
		BASE_LINK="$2"
	fi

	echo "Using $BASE_LINK as eclipse base"

	IDENTIFIER="$1"
	WU_PATH="$ENVIRONMENTS_FOLDER/$IDENTIFIER"
	BASE_PATH="$IDE_FOLDER/$BASE_LINK"

	if [ ! -d "$BASE_PATH" ]
	then
		echo "$BASE_PATH does not exist"
		return 1
	fi

	_copyfolder $IDENTIFIER "$BASE_PATH/eclipse/" eclipse

	if [ -d "$BASE_PATH/workspace" ]
	then
		_copyfolder $IDENTIFIER "$BASE_PATH/workspace/" workspace
	fi

	if [ -f "$BASE_PATH/modifications.sh" ]
	then
		echo Running modification script...
		"$BASE_PATH/modifications.sh" "$WU_PATH"
	fi

	echo
	echo "Completed, execute using the following commands"
	echo " from this directory:  ee"
	echo " from anywhere:        eee $IDENTIFIER"
}

function mkeclipse {
	if [ -z "$1" ]
	then
		echo "An identifier is needed for eclipse dev environment creation"
		return
	fi

	BASE_LINK="currentBaseEclipse"
	IDENTIFIER="$1"
	WU_PATH="$ENVIRONMENTS_FOLDER/$IDENTIFIER"
	BASE_PATH="$IDE_FOLDER/$BASE_LINK"

	_createenv "$IDENTIFIER"

	_copyeclipse "$IDENTIFIER" "$BASE_LINK"

	cd "$WU_PATH"
}

function mkgtenv {
	if [ -z "$1" ]
	then
		echo "An identifier is needed for GlobalTester dev environment creation"
		return
	fi

	BASE_LINK="currentBaseEclipseGlobalTester"
	BASE_PATH="$IDE_FOLDER/$BASE_LINK"

	IDENTIFIER="$1"
	WU_PATH="$ENVIRONMENTS_FOLDER/$IDENTIFIER"

	_createenv "$IDENTIFIER"
	
	if [ -f "$BASE_PATH" ]
	then
		_copyeclipse "$IDENTIFIER" "$BASE_LINK"
	else
		_copyeclipse "$IDENTIFIER"
	fi

	cd "$WU_PATH/$ENV_REPOS_FOLDER"
	clonelocal

	cd "$WU_PATH"
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

	for CURRENT in `find "$MIRROR_FOLDER" -mindepth 2 -maxdepth 2 -type d`
	do
		cd "$CURRENT"
		pwd
		git remote update
	done
	cd "$CURRENT_DIR"
}
