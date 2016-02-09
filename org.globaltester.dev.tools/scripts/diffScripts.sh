#!/bin/bash


set -e

LIST_OF_SOURCE_FILES=`mktemp`
LIST_OF_COPY_FILES=`mktemp`
LIST_OF_ALL_FILES=`mktemp`
FILE_LIST_DIFF=`mktemp`
LIST_FILES_UNIQUE_TO_SOURCE=`mktemp`
LIST_FILES_UNIQUE_TO_COPY=`mktemp`
LIST_FILES_COMMON=`mktemp`

function cleanup {
	if [ -e "$LIST_OF_SOURCE_FILES" ]
	then
		rm $LIST_OF_SOURCE_FILES
	fi
	if [ -e "$LIST_OF_COPY_FILES" ]
	then
		rm $LIST_OF_COPY_FILES
	fi
	if [ -e "$LIST_OF_ALL_FILES" ]
	then
		rm $LIST_OF_ALL_FILES
	fi
	if [ -e "$FILE_LIST_DIFF" ]
	then
		rm $FILE_LIST_DIFF
	fi
	if [ -e "$LIST_FILES_UNIQUE_TO_SOURCE" ]
	then
		rm $LIST_FILES_UNIQUE_TO_SOURCE
	fi
	if [ -e "$LIST_FILES_UNIQUE_TO_COPY" ]
	then
		rm $LIST_FILES_UNIQUE_TO_COPY
	fi
	if [ -e "$LIST_FILES_COMMON" ]
	then
		rm $LIST_FILES_COMMON
	fi
	if [ -e "$MODIFIED" ]
	then
		rm -r $MODIFIED
	fi
}

#trap cleanup EXIT

DIRECT=0
SHOW_UNIQUE=0
REGEX_TEXTFILES='\.js$|\.xml$|\.MF$|\.product$|\.gitignore$|\.properties$|\.project$|\.assembly$'

while [ $# -gt 2 ]
do
	case "$1" in
		"-h"|"--help") echo -en "Usage:\n\n"
			echo -en "`basename $0` <options> SOURCE_DIR COPY_DIR\n\n"
			echo "   Shows the differences between 2 script bundle file trees. The given directories"
			echo "   must be GlobalTester script bundles. Expected changes are by default excluded from"
			echo "   the difference calculation."
			echo
			echo "-d  | --direct                directly use the given folder without copying and"
			echo "                               modification (i.e. do not remove .gitignore and"
			echo "                               filelist.a32 from file lists and do not replace"
			echo "                               the bundle and folder names in text files"
			echo "-u  | --unique                do not show unique files"
			echo "-t  | --text-regex            sets the regex to recognize text files by file name     defaults to $REGEX_TEXTFILES"
			echo "-h  | --help                  display this help"
			exit 1
		;;
		"-d"|"--direct")
			DIRECT=1
			shift
		;;
		"-u"|"--unique")
			SHOW_UNIQUE=0
			shift
		;;
		"-t"|"--text-regex")
			if [[ -z "$2" || $2 == "-"* ]]
			then
				echo "Regex parameter needs a regex to use!"
				exit 1
			fi
			REGEX_TEXTFILES=$2
			shift 2
		;;
		*)
			echo "unknown parameter: $1"
			exit 1;
		;;
	esac
done

SOURCE_DIR=`readlink -f $1`
COMPARE_TO_DIR=`readlink -f $2`

DIFF_PARAMETERS="-w -u"

CURRENT_DIR=`pwd`


cd $SOURCE_DIR
git ls-files --exclude-standard | sort > $LIST_OF_SOURCE_FILES
cd $CURRENT_DIR

cd $COMPARE_TO_DIR
git ls-files --exclude-standard | sort > $LIST_OF_COPY_FILES
cd $CURRENT_DIR


if [ $DIRECT -eq 0 ]
then
	MODIFIED=`mktemp -d`
	echo copying contents to be compared into temp dir $MODIFIED
	cp -a $COMPARE_TO_DIR/. $MODIFIED
	COPY_DIR=$MODIFIED
	echo done...
	
	#extracting project files
	SOURCE_NAME=`sed -n -e 's|\s*<name>\([^<]*\)</name>|\1|p' $SOURCE_DIR/.project | head -n 1`
	COPY_NAME=`sed -n -e 's|\s*<name>\([^<]*\)</name>|\1|p' $COPY_DIR/.project | head -n 1`
	SOURCE_SYMBOLIC_NAME=`basename $SOURCE_DIR`
	COPY_SYMBOLIC_NAME=`basename $COMPARE_TO_DIR`
	if [ -z "$SOURCE_NAME" -o -z "$COPY_NAME" ] 
	then
		echo ERROR: project names could not be extracted
		exit 1
	fi
	
	#do not compare file lists
	echo removing filelist.a32 from files to be compared
	sed -i -e "/^filelist.a32/d" "$LIST_OF_SOURCE_FILES"
	sed -i -e "/^filelist.a32/d" "$LIST_OF_COPY_FILES"	
	
	#do not checksum files
	echo removing checksum.a32 from files to be compared
	sed -i -e "/^checksum.a32/d" "$LIST_OF_SOURCE_FILES"
	sed -i -e "/^checksum.a32/d" "$LIST_OF_COPY_FILES"	
	
	echo Replacements in all files:
	echo "  \"$COPY_NAME\" with \"$SOURCE_NAME\""
	echo "  \"$COPY_SYMBOLIC_NAME\" with \"$SOURCE_SYMBOLIC_NAME\""
	while read -r CURRENT_FILE;
	do
		if [[ $CURRENT_FILE =~ $REGEX_TEXTFILES ]]
		then
			sed -i -e "s|$COPY_NAME|$SOURCE_NAME|g" "$COPY_DIR/$CURRENT_FILE"
			sed -i -e "s|$COPY_SYMBOLIC_NAME|$SOURCE_SYMBOLIC_NAME|g" "$COPY_DIR/$CURRENT_FILE"
		fi
	done <$LIST_OF_COPY_FILES
	echo done...
else
	COPY_DIR=$COMPARE_TO_DIR
fi

cat $LIST_OF_SOURCE_FILES $LIST_OF_COPY_FILES | sort -u -d > $LIST_OF_ALL_FILES

comm -2 -3 $LIST_OF_SOURCE_FILES $LIST_OF_COPY_FILES > $LIST_FILES_UNIQUE_TO_SOURCE
comm -1 -3 $LIST_OF_SOURCE_FILES $LIST_OF_COPY_FILES > $LIST_FILES_UNIQUE_TO_COPY
comm -1 -2 $LIST_OF_SOURCE_FILES $LIST_OF_COPY_FILES > $LIST_FILES_COMMON

if [ $SHOW_UNIQUE -eq 1 ]
	then
	echo Files unique to source
	cat $LIST_FILES_UNIQUE_TO_SOURCE
	echo
	echo Files unique to copy
	cat $LIST_FILES_UNIQUE_TO_COPY
	echo
	echo
fi

echo Following differences exist:
echo

set +e
while read -r CURRENT_FILE;
do
	diff $DIFF_PARAMETERS "$SOURCE_DIR/$CURRENT_FILE" "$COPY_DIR/$CURRENT_FILE"
done <$LIST_FILES_COMMON