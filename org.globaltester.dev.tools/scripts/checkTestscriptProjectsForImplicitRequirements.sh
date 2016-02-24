#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh
. org.globaltester.dev/org.globaltester.dev.tools/scripts/projectHelper.sh
set +e

METAINFDIR='META-INF'
MANIFESTFILE='MANIFEST.MF'
PROJECTFILE='.project'

TESTSCRIPTSIDENTIFIER="testscripts"

#<GIT-specific files>
GITIGNOREFILE='.gitignore'
GITATTRIBUTESFILE='.gitattributes'
#</GIT-specific files>

#<HJP-specific identifiers>
GTIDENTIFIER="GT"
PERSOSIMIDENTIFIER="PersoSim"
EXTENSIONSIDENTIFIER="Extensions to"
TESTSPECIDENTIFIER="TestSpecification"
#</HJP-specific identifiers>



FINDDIRRESULT=""
function findDir(){
	CURRENTRAWDEPENDENCY="$1"
	MYPATH="$2"
	
	PREVDEPTMP=""
	CURRDEPTMP="$CURRENTRAWDEPENDENCY"
	
	#echo INFO: curr wdir is `pwd`
	
	while [[ ! -d "$MYPATH/$CURRDEPTMP" ]]
	do
		PREVDEPTMP="$CURRDEPTMP"
		CURRDEPTMP=$(echo "$PREVDEPTMP" | rev | cut -d '.' -f 2- | rev)
		if [[ "$CURRDEPTMP" == "$PREVDEPTMP" ]]
			then
				#echo WARNING: did not find directory matching "$CURRENTRAWDEPENDENCY"!
				return 1
		fi
	done
	
	FINDDIRRESULT="$CURRDEPTMP"
	
	return 0
}



BASEDIR=`pwd`
echo INFO: base dir is $BASEDIR
CURRENT_REPO=$1
echo INFO: current repo is $CURRENT_REPO

if [[ -d $CURRENT_REPO && $CURRENT_REPO != '.' && $CURRENT_REPO != '..' ]]
	then	
		CURRENT_REPO=$(echo $CURRENT_REPO | cut -d '/' -f 1)
		echo INFO: current repo is: $CURRENT_REPO
		
		for CURRENT_PROJECT in $CURRENT_REPO
			do
				if [[ -d $CURRENT_PROJECT && $CURRENT_PROJECT != '.' && $CURRENT_PROJECT != '..' ]]
					then
						echo ================================================================
						CURRENT_PROJECT=$(echo $CURRENT_PROJECT | cut -d '/' -f 1)
						PATHTOPROJECT="$CURRENT_REPO"/"$CURRENT_PROJECT"
						PATHTOMANIFESTMF="$PATHTOPROJECT/META-INF/MANIFEST.MF"
						echo INFO: currently checked project is: $CURRENT_REPO/$CURRENT_PROJECT
						
						# find required classes or packages
						
						DEBUG=`echo "$CURRENT_REPO" | grep "$TESTSCRIPTSIDENTIFIER"`
						GREPRESULT=$?
						
						if [[ $GREPRESULT == '0' ]]
							then
								# this is a testscripts project
								TESTSCRIPTSPROJECT=true
								
								# get all direct dependencies from *.js and *.xml
								RAWDEPENDENCIESJS=`find "$PATHTOPROJECT/Helper" -name *.js -exec  sed -n -e 's@.*\(\(com\.hjp\|de\.persosim\|org\.globaltester\)\(\.\w\+\)\+\).*@\1@gp' {} \; | sort -u`
								RAWDEPENDENCIESXML=`find "$PATHTOPROJECT/TestSuites" -name *.xml -exec  sed -n -e 's@.*\(\(com\.hjp\|de\.persosim\|org\.globaltester\)\(\.\w\+\)\+\).*@\1@gp' {} \; | sort -u`
								
								RAWDEPENDENCIES="$RAWDEPENDENCIESJS
""$RAWDEPENDENCIESXML"
								RAWDEPENDENCIES=`echo "$RAWDEPENDENCIES" | sort -u`
								RAWDEPENDENCIES=`echo "$RAWDEPENDENCIES" | sed -e "s|\(.*\)\..*|\1|" | sort -u`
							else
								# this is a code project
								TESTSCRIPTSPROJECT=false
								RAWDEPENDENCIESJAVA=`find "$PATHTOPROJECT"/src -name *.java -exec  sed -n -e 's@.*\(\(com\.hjp\|de\.persosim\|org\.globaltester\)\(\.\w\+\)\+\).*@\1@gp' {} \; | sort -u`
								RAWDEPENDENCIES="$RAWDEPENDENCIESJAVA"
						fi
						
						count=0
						echo INFO: found the following raw dependencies
						while read -r CURRENTRAWDEPENDENCY
						do
							echo INFO: \($count\) "$CURRENTRAWDEPENDENCY"
							count=$((count+1))
						done <<< "$RAWDEPENDENCIES"
						echo INFO: -$count- elements
						
						CLEANDEPENDENCIES=""
						while read -r CURRENTRAWDEPENDENCY
						do
							echo ----------------------------------------------------------------
							echo "DEBUG: current raw dependency: $CURRENTRAWDEPENDENCY"
							
							findDir "$CURRENTRAWDEPENDENCY" "."
							FINDDIREXITSTATUS=$?
							
							# greedily find repository containing the raw dependency
							if [[ $FINDDIREXITSTATUS != '0' ]]
								then
									echo WARNING: did not find directory matching "$CURRENTRAWDEPENDENCY" in \.!
									continue
							fi
							
							CURRDEPREPO=$FINDDIRRESULT
							echo INFO: parent repository of "$CURRENTRAWDEPENDENCY" is "$CURRDEPREPO"
							
							#----------------------------------------------------------------
							
							# greedily find project containing the raw dependency
							findDir "$CURRENTRAWDEPENDENCY" "$CURRDEPREPO"
							FINDDIREXITSTATUS=$?
							
							if [[ $FINDDIREXITSTATUS != '0' ]]
								then
									echo WARNING: did not find directory matching "$CURRENTRAWDEPENDENCY" in "$CURRDEPREPO"!
									continue
							fi
							
							CURRDEPPROJECT=$FINDDIRRESULT
							
							# save project containing the raw dependency
							CLEANDEPENDENCIES=`echo -e "$CLEANDEPENDENCIES"'\n'"$CURRDEPPROJECT"`
							echo INFO: parent project of "$CURRENTRAWDEPENDENCY" is "$CURRDEPPROJECT"
							
						done <<< "$RAWDEPENDENCIES"
						
						echo ----------------------------------------------------------------
						
						if [[ $TESTSCRIPTSPROJECT ]]
							then
								# get all indirect dependencies via load from *.js and *.xml
								RAWDEPENDENCIESJSLOAD=`find "$PATHTOPROJECT/Helper" -name *.js -exec grep "^[[:space:]]*load[[:space:]]*([[:space:]]*\".*\"[[:space:]]*," {} \;`
								RAWDEPENDENCIESXMLLOAD=`find "$PATHTOPROJECT/TestSuites" -name *.xml -exec grep "^[[:space:]]*load[[:space:]]*([[:space:]]*\".*\"[[:space:]]*," {} \;`
								
								RAWDEPENDENCIESJSXMLLOAD="$RAWDEPENDENCIESJSLOAD
""$RAWDEPENDENCIESXMLLOAD"
								RAWDEPENDENCIESJSXMLLOAD=`echo "$RAWDEPENDENCIESJSXMLLOAD" | sort -u`
								
								BUNDLENAME=`extractFieldFromManifest "$PATHTOMANIFESTMF" "Bundle-Name"`
								
								CLEANEDBUNDLENAMES=""
								while read -r CURRDEP
								do
									CLEANEDBUNDLENAME=`echo "$CURRDEP" | cut -d '"' -f 2 | cut -d '"' -f 1`
									
									if [[ "$CLEANEDBUNDLENAME" != "$BUNDLENAME" ]]
										then
											CLEANEDBUNDLENAMES="$CLEANEDBUNDLENAMES""$CLEANEDBUNDLENAME
"
									fi
								
								done <<< "$RAWDEPENDENCIESJSXMLLOAD"
								
								CLEANEDBUNDLENAMES=`echo "$CLEANEDBUNDLENAMES" | sort -u`
								CLEANEDBUNDLENAMES="$(echo -e "${CLEANEDBUNDLENAMES}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')"
								
								count=0
								echo INFO: found the following loads
								while read -r CURRDEP
								do
									echo INFO: load \($count\) "$CURRDEP"
									count=$((count+1))
								done <<< "$CLEANEDBUNDLENAMES"
								echo INFO: load -$count- elements
								
								echo cleaned loads: "$CLEANEDBUNDLENAMES"
								
								
								
								
								#MANIFESTREQS=`extractFieldFromManifest "$PATHTOMANIFESTMF" "Require-Bundle"`
								
								echo INFO: Bundle-Name: $BUNDLENAME
								
								echo ----------------------------------------------------------------
						fi
						
						# ----------------------------------------------------------------
						
						UDEPS=`echo "$CLEANDEPENDENCIES" | sort -u`
						UDEPS="$(echo -e "${UDEPS}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')"
						echo INFO: unique dependencies - $UDEPS
						
						echo ----------------------------------------------------------------
						
						# list all final dependencies
						count=0
						echo INFO: found the following unique dependencies in $TESTSCRIPTSIDENTIFIER project
						while read -r CURRENTRAWDEPENDENCY
						do
							echo INFO: \($count\) "$CURRENTRAWDEPENDENCY"
							count=$((count+1))
						done <<< "$UDEPS"
						echo INFO: -$count- elements
						
						echo ----------------------------------------------------------------
						
						# extract and list all requirements listed in the MANIFEST.MF of the test script project
						MANIFESTREQS=`extractFieldFromManifest "$PATHTOMANIFESTMF" "Require-Bundle"`
						
						count=0
						echo INFO: found the following unique dependencies in $PATHTOMANIFESTMF
						while read -r CURRDEP
						do
							echo INFO: \($count\) "$CURRDEP"
							count=$((count+1))
						done <<< "$MANIFESTREQS"
						echo INFO: -$count- elements
						
						echo ----------------------------------------------------------------
						
						# match dependencies from script project against requirements defined in MANIFEST.MF
						while read -r CURRDEPEXPECTED
						do
							GREPREQS=`echo "$MANIFESTREQS" | grep "$CURRDEPEXPECTED"`
							GREPEXITSTATUS=$?
							
							if [[ $GREPEXITSTATUS != '0' ]]
								then
									echo WARNING: missing requirement "$CURRDEPEXPECTED" in "$PATHTOMANIFESTMF"!
									continue
								else
									echo INFO: found dependency for "$CURRDEPEXPECTED" in "$PATHTOMANIFESTMF"!
							fi
							
						done <<< "$UDEPS"
						
						echo ----------------------------------------------------------------
						
						# match dependencies from script project against requirements defined in MANIFEST.MF
						while read -r CURRDEPEXPECTED
						do
							GREPREQS=`echo "$UDEPS" | grep "$CURRDEPEXPECTED"`
							GREPEXITSTATUS=$?
							
							if [[ $GREPEXITSTATUS != '0' ]]
								then
									echo WARNING: obsolete requirement "$CURRDEPEXPECTED" in "$PATHTOMANIFESTMF"!
									continue
								else
									echo INFO: found dependency for "$CURRDEPEXPECTED" in "$PATHTOMANIFESTMF"!
							fi
							
						done <<< "$MANIFESTREQS"
						
						echo ----------------------------------------------------------------
						
						# extend script here
						
				fi
			done
			
fi

echo Script finished successfully