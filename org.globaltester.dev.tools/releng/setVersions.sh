#!/bin/bash
# must be called from root directory for all repos

#   [0-9]\{1,\}

set -e
. org.globaltester.dev/org.globaltester.dev.tools/releng/helper.sh

function replacePom {
	if [ ! -e $1 ] ;then return; fi;
	
	echo "  $1"
	
	#<version>0.0.1-SNAPSHOT</version>
	
	if [ `cat $1 | grep '</parent>' | wc -l` -gt 0 ]
	then
		DETECT='\(.*<parent>.*</parent>.*<version>\)[0-9]\{1,\}\.[0-9]\{1,\}\.[^<]*\(</version>\)'
	else
		DETECT='\(<version>\)[0-9]\{1,\}\.[0-9]\{1,\}\.[^<]*\(</version>\)'
	fi
	REPLACE="\1$2\2"
	sed -i -b -n -e "1h;1!H;\${;g;s|$DETECT|$REPLACE|;p;}" $1
	
}

function replaceManifest {
	if [ ! -e $1 ] ;then return; fi;
	
	echo "  $1"
	
	#Bundle-Version: 0.7.0
	sed -i -e "s|\(Bundle-Version: \)[0-9]\{1,\}\.[0-9]\{1,\}\..*|\1$2|" $1
}

function replaceFeature {
	if [ ! -e $1 ] ;then return; fi;
	
	echo "  $1"
	
	#<feature
	#      id="de.persosim.rcp.feature"
	#      label="PersoSim RCP"
	#      version="0.7.0"
	#      provider-name="HJP Consulting GmbH">
	
	DETECT='\(<feature[^<]*version="\)[0-9]\{1,\}\.[0-9]\{1,\}\.[^"]*\(".*\)'
	REPLACE="\1$2\2"
	sed -i -b -n -e "1h;1!H;\${;g;s|$DETECT|$REPLACE|;p;}" $1
}

function replaceProduct {
	if [ ! -e $1 ] ;then return; fi;
	
	echo "  $1"
	
	#<product name="PersoSim RCP" uid="de.persosim.rcp.product" id="de.persosim.rcp.product" application="org.eclipse.e4.ui.workbench.swt.E4Application" version="0.7.0" useFeatures="true" includeLaunchers="true">

	DETECT='\(<product[^<]*version="\)[0-9]\{1,\}\.[0-9]\{1,\}\.[^"]*\(".*\)'
	REPLACE="\1$2\2"
	sed -i -b -n -e "1h;1!H;\${;g;s|$DETECT|$REPLACE|;p;}" $1
}

function getPom {
	if [ ! -e $1 ] ;then return; fi;
	
	echo "  $1"
	
	#<version>0.0.1-SNAPSHOT</version>
	
	if [ `cat $1 | grep '</parent>' | wc -l` -gt 0 ]
	then
		DETECT='.*<parent>.*</parent>.*<version>\([0-9]\{1,\}\.[0-9]\{1,\}\.[^<]*\)</version>'
	else
		DETECT='<version>\([0-9]\{1,\}\.[0-9]\{1,\}\.[^<]*\)</version>'
	fi
	sed -b -n -e "1h;1!H;\${;g;s|$DETECT|\1$2|;p;}" $1
	
}

function getManifest {
	if [ ! -e $1 ] ;then return; fi;
	
	echo "  $1"
	
	#Bundle-Version: 0.7.0
	sed -e "s|Bundle-Version: \([0-9]\{1,\}\.[0-9]\{1,\}\..*\)|\1$2|" $1
}

function getFeature {
	if [ ! -e $1 ] ;then return; fi;
	
	echo "  $1"
	
	#<feature
	#      id="de.persosim.rcp.feature"
	#      label="PersoSim RCP"
	#      version="0.7.0"
	#      provider-name="HJP Consulting GmbH">
	
	DETECT='<feature[^<]*version="\([0-9]\{1,\}\.[0-9]\{1,\}\.[^"]*\)".*'
	sed -b -n -e "1h;1!H;\${;g;s|$DETECT|\1$2|;p;}" $1
}

function getProduct {
	if [ ! -e $1 ] ;then return; fi;
	
	echo "  $1"
	
	#<product name="PersoSim RCP" uid="de.persosim.rcp.product" id="de.persosim.rcp.product" application="org.eclipse.e4.ui.workbench.swt.E4Application" version="0.7.0" useFeatures="true" includeLaunchers="true">

	DETECT='<product[^<]*version="\([0-9]\{1,\}\.[0-9]\{1,\}\.[^"]*\)".*'
	sed -b -n -e "1h;1!H;\${;g;s|$DETECT|\1$2|;p;}" $1
}



CHANGELOG_FILE_NAME="CHANGELOG"



REPOSITORY=$1

VERSION=$2

TYPE=REPLACE

if [ ! -z "$3" ]
then
	TYPE=UPDATE
fi

echo $VERSION | grep -q $VERSION_REGEXP_PATCH_LEVEL_EVERYTHING
if [ $? -ne 0 ]
then
	echo WARNING: extracted version $VERSION is invalid
fi
echo Modifying repository: $REPOSITORY

for CURRENT_PROJECT in $REPOSITORY/*/
do
	echo Currently updating file in $CURRENT_PROJECT
	
	if [ $TYPE == "UPDATE" ]; then VERSION=`getPom ${CURRENT_PROJECT}pom.xml $VERSION`	
	replacePom ${CURRENT_PROJECT}pom.xml $VERSION
	
	if [ $TYPE == "UPDATE" ]; then VERSION=`getPom ${CURRENT_PROJECT}META-INF/MANIFEST.MF $VERSION`	
	replaceManifest ${CURRENT_PROJECT}META-INF/MANIFEST.MF $VERSION
	
	if [ $TYPE == "UPDATE" ]; then VERSION=`getPom ${CURRENT_PROJECT}feature.xml $VERSION`	
	replaceFeature ${CURRENT_PROJECT}feature.xml $VERSION
	
	if [ $TYPE == "UPDATE" ]; then VERSION=`getPom ${CURRENT_PROJECT}*.product $VERSION`
	replaceProduct ${CURRENT_PROJECT}*.product	$VERSION
done

