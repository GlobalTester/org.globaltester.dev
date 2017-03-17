# parameter handling
while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help")
			echo -e "Usage:\n"
			echo -e "`basename $0` <options> FOLDER\n"
			echo -e "Perform some test script content checks on all files in the given FOLDER."

			exit 1
		;;
		*)
			if [ $# -eq 1 ]
			then
				CURRENT_REPO=$1
				shift 1
			else
				echo "unknown parameter: $1"
				exit 1;
			fi
		;;
		esac
done

if [ ! $CURRENT_REPO ]
then
	echo "Missing parameter: REPO"
	echo "see `basename $0` -h for help"
	exit 1
fi

PATH_FOR_CHECK="`pwd`/`dirname "$0"`/checks/checkFileForUnevenNumberOfQuotationMarks.sh"
cd $CURRENT_REPO


#Check for lines containing an uneven number of quotation marks


find . -type f -name "*.gt" -o -name "*.js" | parallel "$PATH_FOR_CHECK {}"
