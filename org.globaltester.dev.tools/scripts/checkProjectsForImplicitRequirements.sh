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



# parameter handling
VERBOSE=false
while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help")
			echo -e "Usage:\n"
			echo -e "`basename $0` <options> REPO\n"
			echo -e "Perform some dependency checks on all projects in the given REPO."
			echo -e "Must be called from the root of all checked out HJP repositories."
			echo -e "REPO needs to be the local folder name of the repository (which is expected to match the repository name."
			echo
			echo "-v | --verbose          output more progress information"

			exit 1
		;;
		"-v"|"--verbose")
			VERBOSE=true
			shift 1
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



FINDDIRRESULT=""
function findDir {
	CURRENTRAWDEPENDENCY="$1"
	MYPATH="$2"
	
	PREVDEPTMP=""
	CURRDEPTMP="$CURRENTRAWDEPENDENCY"
	
	while [[ ! -d "$MYPATH/$CURRDEPTMP" ]]
	do
		PREVDEPTMP="$CURRDEPTMP"
		CURRDEPTMP=$(echo "$PREVDEPTMP" | rev | cut -d '.' -f 2- | rev)
		if [[ "$CURRDEPTMP" == "$PREVDEPTMP" ]]
			then
				return 1
		fi
	done
	
	echo "$CURRDEPTMP"
}



BASEDIR=`pwd`
$VERBOSE && echo INFO: base dir is \""$BASEDIR"\"
$VERBOSE && echo INFO: current repo is \""$CURRENT_REPO"\"

if [[ -d $CURRENT_REPO && $CURRENT_REPO != '.' && $CURRENT_REPO != '..' ]]
	then	
		CURRENT_REPO=$(echo $CURRENT_REPO | cut -d '/' -f 1)
		$VERBOSE && echo INFO: current repo is \""$CURRENT_REPO"\"
		
		for CURRENT_PROJECT in $CURRENT_REPO/*/
			do
				CURRENT_PROJECT=`basename $CURRENT_PROJECT`
				PATHTOPROJECT="$CURRENT_REPO/$CURRENT_PROJECT"
				if [[ -d $PATHTOPROJECT && $PATHTOPROJECT != '.' && $PATHTOPROJECT != '..' ]]
					then
						$VERBOSE && echo ================================================================
						#CURRENT_PROJECT=$(echo $CURRENT_PROJECT | cut -d '/' -f 1)
						PATHTOMANIFESTMF="$PATHTOPROJECT/META-INF/MANIFEST.MF"
						$VERBOSE && echo INFO: currently checked project is: \""$CURRENT_REPO/$CURRENT_PROJECT"\"
						
						# find required classes or packages
						
						DEBUG=`echo "$CURRENT_REPO" | grep "$TESTSCRIPTSIDENTIFIER"`
						GREPRESULT=$?
						
						IDENTIFY_REFERENCES='.*\(\(com\.hjp\|de\.persosim\|org\.globaltester\)\(\.\w\+\)\+\).*'
						
						
						if [ "$GREPRESULT" -eq 0 ]
							then
								# this is a testscripts project
								$VERBOSE && echo INFO: this is a testscripts project
								TESTSCRIPTSPROJECT=true
								RAWDEPENDENCIES="";
								
								# get all direct dependencies from test cases and java script
								
								RAWDEPENDENCIES=`find "$PATHTOPROJECT" -name "*.gt*" -o -name *.js -exec sed -n -e "s@$IDENTIFY_REFERENCES@\1@gp" {} \; | sort -u`
								RAWDEPENDENCIES=`echo "$RAWDEPENDENCIES" | sed -e "s|\(.*\)\..*|\1|" | sort -u`
							else
								# this is a code project
								$VERBOSE && echo INFO: this is a code project
								TESTSCRIPTSPROJECT=false
								RAWDEPENDENCIES=`find "$PATHTOPROJECT"/src -name *.java -exec sed -n -e "s@$IDENTIFY_REFERENCES@\1@gp" {} \; | sort -u`
						fi
						
						RAWDEPENDENCIES="$(echo -e "${RAWDEPENDENCIES}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')"
						
						if [ "$VERBOSE" == "true" ]
						then
							count=0
							$VERBOSE && echo INFO: found the following raw dependencies
							while read -r CURRENTRAWDEPENDENCY
							do
								$VERBOSE && echo INFO: \($count\) "$CURRENTRAWDEPENDENCY"
								count=$((count+1))
							done <<< "$RAWDEPENDENCIES"
							$VERBOSE && echo INFO: -$count- elements
						fi
						
						CLEANDEPENDENCIES=""
						while read -r CURRENTRAWDEPENDENCY
						do
							$VERBOSE && echo ----------------------------------------------------------------
							$VERBOSE && echo INFO: current raw dependency: "$CURRENTRAWDEPENDENCY"
							
							FINDDIRRESULT=`findDir "$CURRENTRAWDEPENDENCY" "."`
							FINDDIREXITSTATUS=$?
							
							# greedily find repository containing the raw dependency
							if [[ $FINDDIREXITSTATUS != '0' ]]
								then
									echo WARNING: did not find directory matching "$CURRENTRAWDEPENDENCY" in \.!
									continue
							fi
							
							CURRDEPREPO=$FINDDIRRESULT
							$VERBOSE && echo INFO: parent repository of "$CURRENTRAWDEPENDENCY" is "$CURRDEPREPO"
							
							#----------------------------------------------------------------
							
							# greedily find project containing the raw dependency
							FINDDIRRESULT=`findDir "$CURRENTRAWDEPENDENCY" "$CURRDEPREPO"`
							FINDDIREXITSTATUS=$?
							
							if [[ $FINDDIREXITSTATUS != '0' ]]
								then
									echo WARNING: did not find directory matching "$CURRENTRAWDEPENDENCY" in "$CURRDEPREPO"!
									continue
							fi
							
							CURRDEPPROJECT=$FINDDIRRESULT
							
							# save project containing the raw dependency
							CLEANDEPENDENCIES=`echo -e "$CLEANDEPENDENCIES"'\n'"$CURRDEPPROJECT"`
							$VERBOSE && echo INFO: parent project of "$CURRENTRAWDEPENDENCY" is "$CURRDEPPROJECT"
							
						done <<< "$RAWDEPENDENCIES"
						
						$VERBOSE && echo ----------------------------------------------------------------
						
						# add indirect dependencies via load from *.js and *.xml
						if [[ $TESTSCRIPTSPROJECT ]]
							then
								# get all indirect dependencies via load from *.js and *.xml
								RAWDEPENDENCIESJSXMLLOAD=`find "$PATHTOPROJECT" -name "*.js" -o -name "*.gt*" -exec grep "load[[:space:]]*([[:space:]]*\".*\"[[:space:]]*," {} \;`
								RAWDEPENDENCIESJSXMLLOAD="$(echo -e "${RAWDEPENDENCIESJSXMLLOAD}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')"
								RAWDEPENDENCIESJSXMLLOAD=`echo "$RAWDEPENDENCIESJSXMLLOAD" | sort -u`
								
								# strip load commands down to Bundle-Name for each bundle
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
								
								if [[ "$CLEANEDBUNDLENAMES" != "" ]]
									then
										count=0
										$VERBOSE && echo INFO: found the following loads
										while read -r CURRDEP
										do
											$VERBOSE && echo INFO: load \($count\) "$CURRDEP"
											count=$((count+1))
										done <<< "$CLEANEDBUNDLENAMES"
										$VERBOSE && echo INFO: load -$count- elements
										
										# find MANIFEST.MF files matching each Bundle-Name entry
										MANIFESTFILES=`find "." -mindepth 4 -maxdepth 4 -name MANIFEST.MF `
										
										LOADEDPROJECTS=""
										while read -r CURRBUNDLENAME
										do	
											$VERBOSE && echo INFO: looking up MANIFEST.MF with Bundle-Name:"$CURRBUNDLENAME"
											CURRMANIFESTBUNDLESYMBOLICNAME=""
											
											while read -r CURRMANIFEST
											do
												CURRMANIFESTBUNDLENAME=`extractFieldFromManifest "$CURRMANIFEST" "Bundle-Name"`
												if [[ "$CURRBUNDLENAME" != "$CURRMANIFESTBUNDLENAME" ]]
													then
														continue
												fi
												
												CURRMANIFESTBUNDLESYMBOLICNAME=`extractFieldFromManifest "$CURRMANIFEST" "Bundle-SymbolicName"`
												
												$VERBOSE && echo INFO: found Bundle-Name "$CURRBUNDLENAME" in "$CURRMANIFEST"
												$VERBOSE && echo INFO: matching Bundle-SymbolicName is: "$CURRMANIFESTBUNDLESYMBOLICNAME"
												break
											done <<< "$MANIFESTFILES"
											
											if [[ "$CURRMANIFESTBUNDLESYMBOLICNAME" == "" ]]
												then
													echo WARNING: unable to find project with Bundle-Name "$CURRBUNDLENAME"
													continue
											fi
											
											LOADEDPROJECTS="$LOADEDPROJECTS
""$CURRMANIFESTBUNDLESYMBOLICNAME"
											
										done <<< "$CLEANEDBUNDLENAMES"
										
										LOADEDPROJECTS="$(echo -e "${LOADEDPROJECTS}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')"
										
										count=0
										$VERBOSE && echo INFO: found the following loads
										while read -r CURRDEP
										do
											$VERBOSE && echo INFO: load \($count\) "$CURRDEP"
											count=$((count+1))
										done <<< "$LOADEDPROJECTS"
										$VERBOSE && echo INFO: load -$count- elements
										
										CLEANDEPENDENCIES="$CLEANDEPENDENCIES
""$LOADEDPROJECTS"
									else
										$VERBOSE && echo INFO: no indirect dependencies from load
								fi
								
								$VERBOSE && echo ----------------------------------------------------------------
						fi
						
						# ----------------------------------------------------------------
						
						UDEPS=`echo "$CLEANDEPENDENCIES" | sort -u`
						UDEPS="$(echo -e "${UDEPS}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')"
						
						# ----------------------------------------------------------------
						
						# filter self dependency
						$VERBOSE && echo INFO: filtering self-dependency
						MANIFESTBUNDLESYMBOLICNAME=`extractFieldFromManifest "$PATHTOMANIFESTMF" "Bundle-SymbolicName"`
						NEWUDEPS=""
						while read -r CURRENTDEPENDENCY
						do
							if [[ "$CURRENTDEPENDENCY" != "$MANIFESTBUNDLESYMBOLICNAME" ]]
								then
									NEWUDEPS="$NEWUDEPS
""$CURRENTDEPENDENCY"
								else
									$VERBOSE && echo INFO: skipped self-dependency \""$CURRENTDEPENDENCY"\"
							fi
						done <<< "$UDEPS"
						NEWUDEPS="$(echo -e "${NEWUDEPS}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')"
						UDEPS="$NEWUDEPS"
						
						$VERBOSE && echo ----------------------------------------------------------------
						
						# list all final dependencies
						if [[ "$UDEPS" != "" ]]
							then
								count=0
								$VERBOSE && echo INFO: found the following parsed unique dependencies in $TESTSCRIPTSIDENTIFIER project
								while read -r CURRENTRAWDEPENDENCY
								do
									$VERBOSE && echo INFO: \($count\) "$CURRENTRAWDEPENDENCY"
									count=$((count+1))
								done <<< "$UDEPS"
								$VERBOSE && echo INFO: -$count- elements
							else
								$VERBOSE && echo INFO: there are no parsed dependencies
						fi
						
						$VERBOSE && echo ----------------------------------------------------------------
						
						# extract and list all requirements listed in the MANIFEST.MF of the test script project
						MANIFESTREQS=`extractFieldFromManifest "$PATHTOMANIFESTMF" "Require-Bundle"`
						
						if [[ "$MANIFESTREQS" != "" ]]
							then
								count=0
								$VERBOSE && echo INFO: found the following unique dependencies in $PATHTOMANIFESTMF
								while read -r CURRDEP
								do
									$VERBOSE && echo INFO: \($count\) "$CURRDEP"
									count=$((count+1))
								done <<< "$MANIFESTREQS"
								$VERBOSE && echo INFO: -$count- elements
							else
								$VERBOSE && echo INFO: there are no dependencies defined in "$PATHTOMANIFESTMF"
						fi
						
						echo ----------------------------------------------------------------
						
						# match dependencies from script project against requirements defined in MANIFEST.MF
						if [[ "$UDEPS" != "" ]]
							then
								while read -r CURRDEPEXPECTED
								do
									GREPREQS=`echo "$MANIFESTREQS" | grep "$CURRDEPEXPECTED"`
									GREPEXITSTATUS=$?
									
									if [[ $GREPEXITSTATUS != '0' ]]
										then
											echo WARNING: missing requirement "$CURRDEPEXPECTED" in "$PATHTOMANIFESTMF"!
											continue
										else
											$VERBOSE && echo INFO: found dependency for "$CURRDEPEXPECTED" in "$PATHTOMANIFESTMF"!
									fi
									
								done <<< "$UDEPS"
							else
								$VERBOSE && echo INFO: not missing any requirements in "$PATHTOMANIFESTMF"
						fi
						
						echo ----------------------------------------------------------------
						
						# match dependencies from script project against requirements defined in MANIFEST.MF
						if [[ "$MANIFESTREQS" != "" ]]
							then
								while read -r CURRDEPEXPECTED
								do
									GREPREQS=`echo "$UDEPS" | grep "$CURRDEPEXPECTED"`
									GREPEXITSTATUS=$?
									
									if [[ $GREPEXITSTATUS != '0' ]]
										then
											echo WARNING: potentially obsolete requirement "$CURRDEPEXPECTED" in "$PATHTOMANIFESTMF"!
											continue
										else
											$VERBOSE && echo INFO: found dependency for "$CURRDEPEXPECTED" in "$PATHTOMANIFESTMF"!
									fi
									
								done <<< "$MANIFESTREQS"
							else
								$VERBOSE && echo INFO: there are definitely not too many requirements in "$PATHTOMANIFESTMF"
						fi
						
						echo ----------------------------------------------------------------
						
						# extend script here
					
					else
						echo WARNING: illegal project name "$CURRENT_PROJECT"
				fi
			done
	else
		echo WARNING: illegal repo name "$CURRENT_REPO"
fi

$VERBOSE && echo Script finished successfully

exit 0
