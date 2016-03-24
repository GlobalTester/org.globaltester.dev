#!/bin/bash
# must be called from root directory for all repos

#   [0-9]\{1,\}
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh
set +e

function replaceManifest {
	PROJECT=$1
	FILE=$2
	FULLPATH=$PROJECT$FILE
	DATA=$3
	
	if [ -z "$DATA" ]; then return; fi;
	if [ ! -e $FULLPATH ] ;then return; fi;
	echo "  $FULLPATH"
	
	#Bundle-Version: 0.7.0
	sed -i -e "s|\(Bundle-Version: \)[0-9]\{1,\}\.[0-9]\{1,\}\..*|\1$DATA|" $FULLPATH
}

function replaceFeature {
	PROJECT=$1
	FILE=$2
	FULLPATH=$PROJECT$FILE
	DATA=$3
	
	if [ -z "$DATA" ]; then return; fi;
	if [ ! -e $FULLPATH ] ;then return; fi;
	echo "  $FULLPATH"
	
	#<feature
	#      id="de.persosim.rcp.feature"
	#      label="PersoSim RCP"
	#      version="0.7.0"
	#      provider-name="HJP Consulting GmbH">
	
	DETECT='\(<feature[^<]*version="\)[0-9]\{1,\}\.[0-9]\{1,\}\.[^"]*\(".*\)'
	REPLACE="\1$DATA\2"
	sed -i -b -n -e "1h;1!H;\${;g;s|$DETECT|$REPLACE|;p;}" $FULLPATH
}

function replaceProduct {
	PROJECT=$1
	FILE=$2
	FULLPATH=$PROJECT$FILE
	DATA=$3
	
	if [ -z "$DATA" ]; then return; fi;
	if [ ! -e $FULLPATH ] ;then return; fi;
	echo "  $FULLPATH"
	
	#<product name="PersoSim RCP" uid="de.persosim.rcp.product" id="de.persosim.rcp.product" application="org.eclipse.e4.ui.workbench.swt.E4Application" version="0.7.0" useFeatures="true" includeLaunchers="true">

	DETECT='\(<product[^<]*version="\)[0-9]\{1,\}\.[0-9]\{1,\}\.[^"]*\(".*\)'
	REPLACE="\1$DATA\2"
	sed -i -b -n -e "1h;1!H;\${;g;s|$DETECT|$REPLACE|;p;}" $FULLPATH
}

function replaceTestScriptsVersion {
	PROJECT=$1
	FILE=$2
	FULLPATH=$PROJECT$FILE
	DATA=$3
	
	if [ -z "$DATA" ]; then return; fi;
	if [ ! -e $FULLPATH ] ;then return; fi;
	echo "  $FULLPATH"
	
	DETECT="\(<version>\)[^<]*\(</version>\)"
	REPLACE="\1 $DATA \2"
	
	find $PROJECT -name "*.xml" -o -name "*.gt*" -a ! -name "pom.xml" -exec sed -i -e "s|$DETECT|$REPLACE|" {} \;
}

function replaceTestScriptsDate {
	PROJECT=$1
	FILE=$2
	FULLPATH=$PROJECT$FILE
	DATA=$3
	
	if [ -z "$DATA" ]; then return; fi;
	if [ ! -e $FULLPATH ] ;then return; fi;
	echo "  $FULLPATH"
	
	DETECT="\(<date>\)[^<]*\(</date>\)"
	REPLACE="\1 $DATA \2"
	
	find $PROJECT -name "*.xml" -o -name "*.gt*" -exec sed -i -e "s|$DETECT|$REPLACE|" {} \;
}

function stampTestScripts {
	PROJECT=$1
	FILE=$2
	FULLPATH=$PROJECT$FILE
	VERSION=$3
	DATE=$4
	
	if [ -z "$DATA" -o -z "$VERSION" ]; then return; fi;
	if [ ! -e $FULLPATH ] ;then return; fi;
	echo "  $FULLPATH"
		
	replaceTestScriptsVersion "$CURRENT_PROJECT" TestSuites "$VERSION"
	replaceTestScriptsDate "$CURRENT_PROJECT" TestSuites "$DATE"
}


REPOSITORY=$1
VERSION=$2
DATE=$3

echo $VERSION | grep -q "$VERSION_REGEXP_PATCH_LEVEL_EVERYTHING"
if [ $? -ne 0 ]
then
	echo WARNING: parameter version $VERSION is invalid
fi

echo $DATE | grep -q "$DATE_REGEXP"
if [ $? -ne 0 ]
then
	echo WARNING: parameter date $DATE is invalid
fi


echo Modifying repository: $REPOSITORY

for CURRENT_PROJECT in $REPOSITORY/*/
do
	echo Currently updating file in $CURRENT_PROJECT
	
	replaceManifest "$CURRENT_PROJECT" META-INF/MANIFEST.MF "${VERSION}.qualifier"
	replaceFeature "$CURRENT_PROJECT" feature.xml "${VERSION}.qualifier"
	replaceProduct "$CURRENT_PROJECT" *.product "${VERSION}.qualifier"
	stampTestScripts "$CURRENT_PROJECT" TestSuites "$VERSION" "$DATE"
done

