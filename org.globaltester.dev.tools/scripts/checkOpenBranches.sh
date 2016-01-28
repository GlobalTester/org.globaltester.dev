#!/bin/bash
# must be called from root directory
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh


# parameter handling
while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help") echo -en "Usage:\n\n"
			echo -en "`basename $0`"
			echo -en "This must be called from the root of all checked out HJP repositories."
			exit 1
		;;
		*)
			echo "unknown parameter: $1"
			exit 1;
		;;
	esac
done

# Repo changelog generation
curDir=`pwd`

BRANCHES=
for curProj in */;
do
	cd "$curProj"
	BRANCHES+=`git branch -al --no-merged & echo -e "\n"`
	cd $curDir
done

echo "$BRANCHES" | sort -u
	
