#!/bin/bash
# must be called from root directory
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

# parameter handling
while [ $# -gt 1 ]
do
	case "$1" in
		"-h"|"--help") 
			echo -e "Usage:\n"
			echo -e "`basename $0` <path_to_project>\n"
			echo -e "This must be called from the root of all checked out secunet repositories."
			exit 1
		;;
		*)
			echo "unknown parameter: $1"
			exit 1;
		;;
	esac
done

PROJECT=`getAbsolutePath "$1"`


# change dir to o.g.d.tools project
cd org.globaltester.dev/org.globaltester.dev.tools

#ensure tools are compiled
mvn compile

#call class via maven
mvn exec:java -Dexec.mainClass="org.globaltester.dev.tools.TestScriptChecksum" -Dexec.args="$PROJECT"

