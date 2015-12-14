#! /bin/bash
#
# Checkout all repos accessible with the given private key and build the product.
#

PATTERN='(\.releng|\.integrationtest|\.scripts)($|\/)'

#set default values

REPOSITORY=com.hjp.releng
FOLDER=com.hjp.releng
SOURCE=git@git.hjp-consulting.com

PARAMETER_NUMBER=0
KEEP_POM=0
FULL_CLONE=0


while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help") echo -en "Usage:\n\n"
			echo -en "testRepoBuild.sh <options>\n\n"
			echo "-k | --key	the private key to be used for clone			defaults to user key"
			echo "		 Setting this as the first parameter also sets folder"
			echo "		 to <value>.releng and repo to <value>"
			echo "-r | --repo	sets the repository name for the build			defaults to $REPOSITORY"
			echo "		 Setting this as the first parameter also sets folder"
			echo "		 to <value>.releng"
			echo "-f | --folder	sets the folder name for the build			defaults to $FOLDER"
			echo "-p | --pattern	the pattern inversely matched to exclude folders	defaults to $PATTERN"
			echo "-b | --branch	the branch to be used for building"
			echo "-m | --maven	sets maven arguments to be used"
			echo "-s | --source	the source to be used"
			echo "-b | --branch	the branch to be used for building"
			echo "-kp| --keep-pom	do not update the pom.xml file of the chosen folder"
			echo "-h | --help	display this help"
			exit 1
		;;
		"-k"|"--key")
			if [[ -z "$2" || "$2" == "-"* ]]
			then
				echo "Key file parameter needs a file to use!"
				exit 1
			fi
			KEY=$2
			if [ $PARAMETER_NUMBER -eq 0 ]
			then
				FOLDER="$(basename $KEY).releng"
				REPOSITORY="$(basename $KEY)"
			fi
			shift 2
		;;
		"-p"|"--pattern")
			if [[ -z "$2" ]]
			then
				echo "Pattern is missing!"
				exit 1
			fi
			PATTERN=$2
			shift 2
		;;
		"-f"|"--folder")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Folder parameter needs a folder to use!"
				exit 1
			fi
			FOLDER=$2
			shift 2
		;;
		"-r"|"--repo")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Repository parameter needs a folder to use!"
				exit 1
			fi
			REPOSITORY=$2
			if [ $PARAMETER_NUMBER -eq 0 ]
			then
				FOLDER="$REPOSITORY.releng"
			fi
			shift 2
		;;
		"-b"|"--branch")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Branch parameter needs a branch to use!"
				exit 1
			fi
			BRANCH=$2
			shift 2
		;;
		"-m"|"--maven")
			if [ -z "$2" ]
			then
				echo "Maven argument parameter needs a value!"
				exit 1
			fi
			MAVEN=$2
			shift 2
		;;
		"-s"|"--source")
			if [ -z "$2" ]
			then
				echo "Source argument parameter needs a value!"
				exit 1
			fi
			SOURCE=$2
			shift 2
		;;
		"-kp"|"--keep-pom")
			KEEP_POM=1
			shift 1
		;;
		"-f"|"--full")
			FULL_CLONE=1
			shift 1
		;;
		*)
			echo "unknown parameter!"
			exit 1;
		;;
	esac
	
	PARAMETER_NUMBER=$(( $PARAMETER_NUMBER + 1 ))
done

if [ -z "$REPOSITORY" ]
then
	echo "No repository was set or could not be derived from other parameters"
	exit 1
fi

if [ -z "$FOLDER" ]
then
	echo "No folder was set or could not be derived from other parameters"
	exit 1
fi

RELENG=$REPOSITORY/$FOLDER

#start separate ssh-agent and ensure that it is killed afterwards
eval `ssh-agent -s`
trap "{ echo exited script, cleaning up...; kill $SSH_AGENT_PID; echo done; }" SIGINT SIGTERM EXIT

#register specific private key in ssh-agent
ssh-add $KEY



#operate in a temporary directory
DIR=`mktemp -d`
cd $DIR

#clone given releng repo

case "$SOURCE" in
	PersoSim|persosim|PERSOSIM)
		CLONE_URI=git@github.com:PersoSim/
	;;
	HJP|hjp|*)
		CLONE_URI=git@git.hjp-consulting.com:
	;;
esac

CLONERESULT=0

if [ $FULL_CLONE -eq 1 ]
then
	#extract repo names from git
	REPOS_TO_CLONE=`ssh git@git.hjp-consulting.com | sed -e '/^ R/!d' | sed "s/^[ RW\t]*//" | grep "\."`
else
	#clone releng repo
	git clone ${CLONE_URI}${REPOSITORY}
	CLONERESULT=$?
	#extract repo names from pom
	if [ -e $RELENG/pom.xml ]
	then
		REPOS_TO_CLONE=`cat $RELENG/pom.xml | grep '<module>' | sed -e 's|.*\.\.\/\.\.\/\([^/]*\)\/.*<\/module>|\1|' | grep -v "$REPOSITORY" | sort -u`
	else
		echo No releng pom file found to extract a file list from
		CLONERESULT=1
	fi
fi

for currentRepo in $REPOS_TO_CLONE; do git clone ${CLONE_URI}$currentRepo; CLONERESULT=$(( $CLONERESULT + $? )); if [ $CLONERESULT -ne 0 ] ; then break; fi; done

CLONERESULT=$(( $CLONERESULT + $? ))

if [ $CLONERESULT -eq 0 -a ! -z "$BRANCH" ]
then
	for curProj in */; do cd "$curProj";echo -en "\e[36m" ; pwd; echo -en "\e[0m"; git checkout "$BRANCH"; cd ..; done
fi


if [ $CLONERESULT -eq 0 ]
then 
	cd $RELENG
	if [ $KEEP_POM -eq 0 ]
	then 
		POM=pom.xml
		sed -i ':a;N;$!ba;s/<modules>.*/<modules>/g' $POM
		find ../.. -maxdepth 2 -mindepth 2 -type d ! -name ".*" | grep -E -v $PATTERN | sed -e "s/\(.*\)/    <module>\1<\/module>/" | sort -d >> $POM
		echo -e "  </modules>\n\n</project>" >> $POM	
	fi
	
	#Test the build
	mvn clean verify $MAVEN
	BUILDRESULT=$?
	cd ../..
fi

# print a little summary


echo -e "\n\n\n===================="
echo "Repos cloned"
ls -1

echo "===================="

if [ $CLONERESULT -ne 0 ]
then
	echo "Clone was incomplete"
else
	echo "Git changes after build"
	curDir=`pwd`; for curProj in */; do cd "$curProj"; git status -s; cd $curDir; done
	echo "===================="
	echo "Build for $REPOSITORY in $DIR"
	echo "===================="
	echo "Exit code of build was $BUILDRESULT"
fi
echo "===================="



#cleanup
read -p "Do you want to open a shell and investigate the build dir? y/N" OPEN_SHELL
case "$OPEN_SHELL" in
	Yes|yes|Y|y)
		bash
		read -p "Do you want to keep the build dir $DIR? y/N" REMOVE_DIR
		case "$REMOVE_DIR" in
			Yes|yes|Y|y)
				echo "$DIR will not be removed"
			;;
			No|no|N|n|""|*)
				echo "deleting $DIR"
				rm -rf $DIR
				echo "removed $DIR"
			;;
		esac
		;;
		No|no|N|n|""|*)
			echo "deleting $DIR"
			rm -rf $DIR
			echo "done"
		;;
esac
