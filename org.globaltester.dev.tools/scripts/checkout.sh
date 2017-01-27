#! /bin/bash
#
# Checkout all repos accessible with the given private key and build the product.
#

#set default values
REPOSITORY=org.globaltester.platform
DESTINATION=.
SOURCE=GlobalTester

PARAMETER_NUMBER=0
FULL_CLONE=0
INTERACTIVE=1
IGNORE_EXISTING=0
MIRROR=""

while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help") echo -en "Usage:\n\n"
			echo -en "`basename $0` <options>\n\n"
			echo "-r  | --repo            sets the repository name for the build                 defaults to $REPOSITORY"
			echo "-f  | --folder          sets the project folder name for the build             defaults to \$REPOSITORY.releng"
			echo "-d  | --destination     sets the destination folder name for the checkout      defaults to $DESTINATION"
			echo "-b  | --branch          the branch to be checked out"
			echo "-s  | --source          the source to be used                                  defaults to $SOURCE"
			echo "-i  | --ignore          ignores existing repository folders"
			echo "-fc | --full            clone all accessible repositories"
			echo "-m  | --mirror          setup mirror repositories, see git help clone for details"
			echo "-ni | --non-interactive assume answers needed to proceed"
			echo "-h  | --help            display this help"
			exit 1
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
			shift 2
		;;
		"-d"|"--destination")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Destination parameter needs a folder to use!"
				exit 1
			fi
			DESTINATION=$2
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
		"-s"|"--source")
			if [ -z "$2" ]
			then
				echo "Source argument parameter needs a value!"
				exit 1
			fi
			SOURCE=$2
			shift 2
		;;
		"-i"|"--ignore")
			IGNORE_EXISTING=1
			shift 1
		;;
		"-m"|"--mirror")
			MIRROR="--mirror"
			shift 1
		;;
		"-ni"|"--non-interactive")
			INTERACTIVE=0
			shift 1
		;;
		"-fc"|"--full")
			FULL_CLONE=1
			shift 1
		;;
		*)
			echo "unknown parameter: $1"
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
	FOLDER="$REPOSITORY.releng"
	echo "No folder was set. Using default: $FOLDER"
fi

RELENG=$REPOSITORY/$FOLDER

if [ -z $DESTINATION ]
then
	DIR=.
else 
	DIR=$DESTINATION
fi

if [ $INTERACTIVE -ne 0 ]
then
	read -p "Do you want to checkout $REPOSITORY into $(cd "$(dirname "$DIR")" && pwd)? y/N" PROCEED
	case "$PROCEED" in
		Yes|yes|Y|y)
			echo "Starting checkout..."
		;;
		No|no|N|n|""|*)
			echo "No changes"
			exit 1
		;;
	esac
fi

cd $DIR

#clone given releng repo

FULLCLONE_ALLOWED=0
case "$SOURCE" in
	PersoSim|persosim|PERSOSIM)
		CLONE_URI=git@github.com:PersoSim/
	;;
	GlobalTester|globaltester|gt|GT|GLOBALTESTER)
		CLONE_URI=git@github.com:GlobalTester/
	;;
	bitbucket)
		CLONE_URI=ssh://git@bitbucket.secunet.de:7999/gt/
	;;
	gitolite)
		CLONE_URI=git@git.globaltester.org:
		FULLCLONE_ALLOWED=1
	;;
	*)
		CLONE_URI=$SOURCE
		FULLCLONE_ALLOWED=1
	;;
esac

if [ $FULL_CLONE -eq 1 -a $FULLCLONE_ALLOWED -ne 1 ]
then
	echo "A full clone is only possible using the secunet servers."
	exit 1
fi

CLONERESULT=0
ACTUALLY_CLONED=

if [ $FULL_CLONE -eq 1 ]
then
	#extract repo names from git
	REPOS_TO_CLONE=`ssh git@git.globaltester.org | sed -e '/^ R/!d' | sed "s/^[ RW\t]*//" | grep "\."`
else

	REF="HEAD"
	if [ ! -z "$BRANCH" ]
	then
		REF="$BRANCH"
	fi
	
	REPOS_TO_CLONE=`git archive --remote=${CLONE_URI}${REPOSITORY} $REF:$FOLDER pom.xml | tar -xO | grep '<module>' | sed -e 's|.*\.\.\/\.\.\/\([^/]*\)\/.*<\/module>.*|\1|' | sort -u`

	#clone releng repo
#	if [ -d $REPOSITORY ]
#	then
#		if [ $IGNORE_EXISTING -eq 0 ]
#		then
#			echo Releng repository already existing
#			exit 1
#		else
#			CLONERESULT=0
#		fi
#	else
#		git clone ${CLONE_URI}${REPOSITORY}
#	fi
#		
#	CLONERESULT=$?
#	
#	if [ $CLONERESULT -eq 0 ]
#	then
#		ACTUALLY_CLONED=${ACTUALLY_CLONED}"$REPOSITORY\n"
#		if [ ! -z "$BRANCH" ]
#		then
#			cd "$REPOSITORY";git checkout "$BRANCH"; cd ..;
#		fi
#	fi
#	
#	
#	#extract repo names from pom
#	if [ -e $RELENG/pom.xml ]
#	then
#		REPOS_TO_CLONE=`cat $RELENG/pom.xml | grep '<module>' | sed -e 's|.*\.\.\/\.\.\/\([^/]*\)\/.*<\/module>.*|\1|' | sort -u`
#	else
#		echo No releng pom file found to extract a file list from
#		exit 1
#	fi

fi

for currentRepo in $REPOS_TO_CLONE
do
	if [ $IGNORE_EXISTING -eq 1 -a -d $currentRepo ]
	then
		continue
	fi
	git clone $MIRROR ${CLONE_URI}$currentRepo
	CLONERESULT=$(( $CLONERESULT + $? ))
	if [ $CLONERESULT -ne 0 ]
	then
		break
	else
		ACTUALLY_CLONED=${ACTUALLY_CLONED}"$currentRepo\n"
	fi
done

if [ $CLONERESULT -eq 0 -a ! -z "$BRANCH" ]
then
	for curProj in */; do cd "$curProj";echo -en "\e[36m" ; pwd; echo -en "\e[0m"; git checkout "$BRANCH"; cd ..; done
fi


# print a little summary


echo -e "\n\n\n===================="
echo -e "Repos cloned\n"
echo -e $ACTUALLY_CLONED
echo "===================="

if [ $CLONERESULT -ne 0 ]
then
	echo "Clone was incomplete"
else
	echo "Checkout of $REPOSITORY and related in $DIR"
fi
echo "===================="
exit $CLONERESULT
