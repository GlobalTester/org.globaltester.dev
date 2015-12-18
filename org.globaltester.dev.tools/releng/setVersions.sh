#!/bin/bash
# must be called from root directory for all repos

#   [0-9]\{1,\}

function replacePom {
	if [ ! -e $1 ] ;then return; fi;
	#<version>0.0.1-SNAPSHOT</version>
	sed -i -e "s|\(<version>\)[0-9]\{1,\}\.[0-9]\{1,\}\..*\(</version>\)|\1$2\2|" $1
}
function replaceManifest {
	if [ ! -e $1 ] ;then return; fi;
	#Bundle-Version: 0.7.0
	sed -i -e "s|\(Bundle-Version: \)[0-9]\{1,\}\.[0-9]\{1,\}\..*|\1$2|" $1
}
function replaceFeature {
	if [ ! -e $1 ] ;then return; fi;
	#<feature
	#      id="de.persosim.rcp.feature"
	#      label="PersoSim RCP"
	#      version="0.7.0"
	#      provider-name="HJP Consulting GmbH">
	sed -i -e "s|<\(feature.*version=\"\)[0-9]\{1,\}\.[0-9]\{1,\}\..*\)\(\".*</feature>\)|\1$2\2|" $1
}
function replaceProduct {
	if [ ! -e $1 ] ;then return; fi;
	#<product name="PersoSim RCP" uid="de.persosim.rcp.product" id="de.persosim.rcp.product" application="org.eclipse.e4.ui.workbench.swt.E4Application" version="0.7.0" useFeatures="true" includeLaunchers="true">

	sed -e "s|<\(product.*version=\"\)[0-9]\{1,\}\.[0-9]\{1,\}\..*\)\(\".*</product>\)|\1$2\2|" $1
}



CHANGELOG_FILE_NAME="CHANGELOG"



VERSION=



while read CURRENT_LINE; do
	VERSION=`echo $CURRENT_LINE | sed -e 's|Version \([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\) ([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\})|\1|g'`
	if [ ! -z "$VERSION" ]
	then
		echo $VERSION will be set for all files in this repository
		break
	fi
done < $CHANGELOG_FILE_NAME



for CURRENT_PROJECT in */
do
	echo $CURRENT_PROJECT
	replacePom ${CURRENT_PROJECT}pom.xml $VERSION
	replaceManifest ${CURRENT_PROJECT}META_INF/MANIFEST.MF $VERSION
	replaceFeature ${CURRENT_PROJECT}feature.xml $VERSION
	replaceProduct ${CURRENT_PROJECT}*product.xml $VERSION
done


