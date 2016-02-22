#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh
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
		#echo INFO: CURRDEPTMP="$CURRDEPTMP"
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
		DEBUG=`echo "$CURRENT_REPO" | grep "$TESTSCRIPTSIDENTIFIER"`
		GREPRESULT=$?
		
		if [[ $GREPRESULT != '0' ]]
			then
				echo ERROR: this is not a \"$TESTSCRIPTSIDENTIFIER\" repository
				exit 1
		fi
		
		CURRENT_REPO=$(echo $CURRENT_REPO | cut -d '/' -f 1)
		echo INFO: current repo is: $CURRENT_REPO
		
		for CURRENT_PROJECT in $CURRENT_REPO
			do
				if [[ -d $CURRENT_PROJECT && $CURRENT_PROJECT != '.' && $CURRENT_PROJECT != '..' ]]
					then
						echo ================================================================
						CURRENT_PROJECT=$(echo $CURRENT_PROJECT | cut -d '/' -f 1)
						echo INFO: currently checked project is: $CURRENT_REPO/$CURRENT_PROJECT
						DEPENDENCIESTMP1=`find "$CURRENT_PROJECT" -name *.xml -o -name *.js -exec  sed -n -e 's@.*\(\(com\.hjp\|de\.persosim\|org\.globaltester\)\(\.\w\+\)\+\).*@\1@gp' {} \; | sort -u`
						RAWDEPENDENCIES=`echo "$DEPENDENCIESTMP1" | sed -e "s|\(.*\)\..*|\1|"`
						
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
							
							if [[ $FINDDIREXITSTATUS != '0' ]]
								then
									echo WARNING: did not find directory matching "$CURRENTRAWDEPENDENCY" in \.!
									continue
							fi
							
							CURRDEPREPO=$FINDDIRRESULT
							echo INFO: parent repository of "$CURRENTRAWDEPENDENCY" is "$CURRDEPREPO"
							
							#----------------------------------------------------------------
							
							findDir "$CURRENTRAWDEPENDENCY" "$CURRDEPREPO"
							FINDDIREXITSTATUS=$?
							
							if [[ $FINDDIREXITSTATUS != '0' ]]
								then
									echo WARNING: did not find directory matching "$CURRENTRAWDEPENDENCY" in "$CURRDEPREPO"!
									continue
							fi
							
							CURRDEPPROJECT=$FINDDIRRESULT
							CLEANDEPENDENCIES=`echo -e "$CLEANDEPENDENCIES"'\n'"$CURRDEPPROJECT"`
							echo INFO: parent project of "$CURRENTRAWDEPENDENCY" is "$CURRDEPPROJECT"
							
						done <<< "$RAWDEPENDENCIES"
						
						#echo INFO: clean dependencies - $CLEANDEPENDENCIES
						UDEPS=`echo "$CLEANDEPENDENCIES" | sort -u`
						UDEPS="$(echo -e "${UDEPS}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
						echo INFO: unique dependencies - $UDEPS
						
						count=0
						echo INFO: found the following unique dependencies
						while read -r CURRENTRAWDEPENDENCY
						do
							echo INFO: \($count\) "$CURRENTRAWDEPENDENCY"
							count=$((count+1))
						done <<< "$UDEPS"
						echo INFO: -$count- elements
						
				fi
			done
			
fi

echo Script finished successfully