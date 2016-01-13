#! /bin/bash
#
# Checkout all repos accessible with the given private key and build the product.
#

function removeResults {
	echo "deleting $DIR"
	rm -rf $DIR
	echo "done"
}

function stopAgent {
	if [ $SSH_AGENT_STARTED -eq 1 ]
	then 
		kill $SSH_AGENT_PID
		SSH_AGENT_STARTED=0
	fi
}

function inspection {
	if [ $INSPECT_BUILD -eq 1 ]
	then
		bash
			read -p "Do you want to keep the build dir $DIR? y/N" REMOVE_DIR
			case "$REMOVE_DIR" in
				Yes|yes|Y|y)
					echo "$DIR will not be removed"
				;;
				No|no|N|n|""|*)
					removeResults
				;;
			esac
	else
		removeResults
	fi
}

function absoluteFilename {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

PARAMETER_NUMBER=0

REPOSITORY=com.hjp.internal
FOLDER=com.hjp.internal.releng
PATTERN='(\.releng|\.integrationtest)($|\/)'
INSPECT_BUILD=0
MAVEN="clean verify"
KEEP_POM=1

OWN_PARAMETERS_CHECKED=0
CHECKOUT_SCRIPT=$(absoluteFilename "`dirname $0`/checkout.sh")

while [ $# -gt 0 -a $OWN_PARAMETERS_CHECKED -ne 1 ]
do
	case "$1" in
		"-h"|"--help") echo -en "Usage:\n\n"
			echo -en "`basename $0` <options> -- <optionsToCheckoutScript>\n\n"
			echo "-k | --key          the private key to be used for clone                     defaults to user key"
			echo "                     Setting this as the first parameter also sets folder"
			echo "                     to <value>.releng and repo to <value>"
			echo "-r | --repo         sets the repository name for the build                   defaults to $REPOSITORY"
			echo "                     Setting this as the first parameter also sets folder"
			echo "                     to <value>.releng"
			echo "-f | --folder       sets the project folder name for the build               defaults to $FOLDER"
			echo "-m | --maven        sets maven arguments to be used                          defaults to $MAVEN"
			echo "-g | --generate-pom update the pom.xml file of the chosen product folder"
			echo "-p | --pattern      the pattern inversely matched to exclude folder          defaults to $PATTERN"
			echo "-s | --script       sets checkout scripts to be used                         defaults to $CHECKOUT_SCRIPT"
			echo "-i | --inspect      open a shell to inspect the build directory"
			echo "-h | --help         display this help"
			if [ -e $CHECKOUT_SCRIPT ]
			then
				$CHECKOUT_SCRIPT -h
			fi
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
		"-m"|"--maven")
			if [ -z "$2" ]
			then
				echo "Maven argument parameter needs a value!"
				exit 1
			fi
			MAVEN=$2
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
		"-g"|"--generate-pom")
			KEEP_POM=0
			shift 1
		;;
		"-i"|"--inspect")
			INSPECT_BUILD=1
			shift 1
		;;
		"--")
			OWN_PARAMETERS_CHECKED=1
			shift 1
		;;
		*)
			echo "unknown parameter: $1"
			exit 1;
		;;
	esac
	
	PARAMETER_NUMBER=$(( $PARAMETER_NUMBER + 1 ))
done

RELENG=$REPOSITORY/$FOLDER

SSH_AGENT_STARTED=0

trap 'stopAgent; removeResults' SIGINT SIGTERM
trap 'inspection; stopAgent' EXIT

if [ ! -z "$KEY" ]
then
	#start separate ssh-agent and ensure that it is killed afterwards
	eval `ssh-agent -s`
	SSH_AGENT_STARTED=1

	#register specific private key in ssh-agent
	ssh-add $KEY
fi


#operate in a temporary directory
DIR=`mktemp -d`
cd $DIR

CHECKOUT_SCRIPT_PARAMS="-f $FOLDER -r $REPOSITORY -s hjp -ni -d $DIR $@"
echo "Calling checkout script with parameters: $CHECKOUT_SCRIPT_PARAMS"

CLONERESULT=0
$CHECKOUT_SCRIPT $CHECKOUT_SCRIPT_PARAMS

CLONERESULT=$?


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
	mvn $MAVEN
		
	BUILDRESULT=$?
	cd ../..
fi

# print a little summary

echo -e "\n\n\n===================="
if [ $CLONERESULT -ne 0 ]
then
	echo "Clone was incomplete"
else
	if [ $BUILDRESULT -ne 0 ]
	then
		echo "Build was not successful with exit code $BUILDRESULT"
	else
		echo "Git changes after build"
		curDir=`pwd`; for curProj in */; do cd "$curProj"; git status -s; cd $curDir; done
		echo "===================="
		echo "Build for $REPOSITORY in $DIR"
	fi
fi
echo "===================="
