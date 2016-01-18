#!/bin/bash
# must be called from root directory for all repos

#   [0-9]\{1,\}

. org.globaltester.dev/org.globaltester.dev.tools/releng/helper.sh

function replacePom {
	PROJECT=$1
	FILE=$2
	FULLPATH=$PROJECT$FILE
	DATA=$3
	
	if [ -z "$DATA" ]; then return; fi;	
	if [ ! -e $FULLPATH ] ;then return; fi;
	echo "  $FULLPATH"
	
	
	#<version>0.0.1-SNAPSHOT</version>
	
	if [ `cat $FULLPATH | grep '</parent>' | wc -l` -gt 0 ]
	then
		DETECT='\(.*<parent>.*</parent>.*<version>\)[0-9]\{1,\}\.[0-9]\{1,\}\.[^<]*\(</version>\)'
	else
		DETECT='\(<version>\)[0-9]\{1,\}\.[0-9]\{1,\}\.[^<]*\(</version>\)'
	fi
	REPLACE="\1$DATA\2"
	sed -i -b -n -e "1h;1!H;\${;g;s|$DETECT|$REPLACE|;p;}" $FULLPATH
	
}

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
	
	find $PROJECT -name "*.xml" -exec sed -i -e "s|$DETECT|$REPLACE|" {} \;
	
#		<dependency>
#			<artifactId>com.hjp.globaltester.scripts.is.sac</artifactId>
#			<groupId>com.hjp.globaltester</groupId>
#			<version>0.1.0</version>
#			<classifier>com.hjp.globaltester.scripts.is.sac.assembly</classifier>
#			<type>zip</type>
#		</dependency>
	
	ID=`echo $PROJECT | sed -e "s|[^/]*/\([^/]*\).*|\1|"`
	
	DETECT_DEPENDENCY="\(<version>\).*\(</version>\)"
	REPLACE_DEPENDENCY="\1$DATA\2"
	
	find . -maxdepth 2 -mindepth 2 -name "*.scripts" -exec sed -i -e "/<artifactId>$ID<\/artifactId>/,/<\/dependency>/ s|$DETECT_DEPENDENCY|$REPLACE_DEPENDENCY|" {}/pom.xml \;
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
	
	find $PROJECT -name "*.xml" -exec sed -i -e "s|$DETECT|$REPLACE|" {} \;
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
	
	replacePom "$CURRENT_PROJECT" pom.xml "$VERSION"
	replaceManifest "$CURRENT_PROJECT" META-INF/MANIFEST.MF "$VERSION"
	replaceFeature "$CURRENT_PROJECT" feature.xml "$VERSION"
	replaceProduct "$CURRENT_PROJECT" *.product "$VERSION"
	stampTestScripts "$CURRENT_PROJECT" TestSuites "$VERSION" "$DATE"
done

