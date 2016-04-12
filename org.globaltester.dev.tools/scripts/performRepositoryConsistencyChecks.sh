#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh
set +e

VERBOSE=false

METAINFDIR='META-INF'
MANIFESTFILE='MANIFEST.MF'
PROJECTFILE='.project'
POMFILE='pom.xml'

#<MANIFEST.MF-specific identifiers>
BUNDLENAMEIDENTIFIER="Bundle-Name"
BUNDLESYMBOLICNAMEIDENTIFIER="Bundle-SymbolicName"
BUNDLEVENDORLINEIDENTIFIER="Bundle-Vendor"
#</MANIFEST.MF-specific identifiers>

EXPECTEDVENDORSTRING="HJP Consulting GmbH"
TESTSCRIPTSIDENTIFIER="testscripts"

#<GIT-specific files>
GITIGNOREFILE='.gitignore'
GITATTRIBUTESFILE='.gitattributes'
GITATTRIBUTESFILEMATCH='../org.globaltester.dev/.gitattributes'
#</GIT-specific files>

#<HJP-specific identifiers>
GTIDENTIFIER="GT"
PERSOSIMIDENTIFIER="PersoSim"
EXTENSIONSIDENTIFIER="Extensions to"
TESTSPECIDENTIFIER="TestSpecification"
#</HJP-specific identifiers>

BSN[0]="test"
BSN[1]="ui"
BSN[2]="integrationtest"
BSN[3]="feature"
BSN[4]="site"
BSN[5]="product"
BSN[6]="releng"
BSN[7]="sample"
BSN[8]="ui.test"
BSN[9]="doc"
BSN[10]="scripts"
BSN[11]="tools"
BSN[12]="ui.integrationtest"

BN[0]="Test"
BN[1]="UI"
BN[2]="Integration Test"
BN[3]="Feature"
BN[4]="Site"
BN[5]="Product"
BN[6]="Releng"
BN[7]="Sample"
BN[8]="UI Test"
BN[9]="Doc"
BN[10]="Scripts"
BN[11]="Tools"
BN[12]="UI Integration Test"

# parameter handling
while [ $# -gt 0 ]
do
	case "$1" in
		"-h"|"--help")
			echo -e "Usage:\n"
			echo -e "`basename $0` <options> REPO\n"
			echo -e "Perform some consistency checks on all projects in the given REPO."
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
	echo "Missing paramter: REPO"
	echo "see `basename $0` -h for help"
	exit 1
fi

function extractValue(){
	FILE=$1
	IDENTIFIER=$2
	
	LINE=`grep $IDENTIFIER $FILE`
	GREPRESULT=$?
	
	if [[ $GREPRESULT != '0' ]]
		then
			return 1
	fi
	
	VALUE=$(echo $LINE | cut -d ':' -f 2- | cut -d ';' -f 1 | sed 's|^\s*||')
	
	return 0
}

echo Checking repository: $CURRENT_REPO

if [[ -d $CURRENT_REPO && $CURRENT_REPO != '.' && $CURRENT_REPO != '..' ]]
	then
		$VERBOSE && echo "################################################################"
		CURRENT_REPO=$(echo $CURRENT_REPO | cut -d '/' -f 1)
		$VERBOSE && echo INFO: current repo is: $CURRENT_REPO
		cd $CURRENT_REPO
		CURRENTDIR=$CURRENT_REPO
		$VERBOSE && echo INFO: current dir is: $CURRENTDIR
		
		# check for the presence of a .gitignore file on repository level
		if [ -f $GITIGNOREFILE ]
			then
				$VERBOSE && echo INFO: file $GITIGNOREFILE found at $CURRENTDIR "as expected (content currently unchecked)"
			else
				echo ERROR: file $GITIGNOREFILE NOT found at $CURRENTDIR
				exit 1
		fi
		
		# check for the presence of a .gitattributes file on repository level
		if [ -f $GITATTRIBUTESFILE ]
			then
				HASH1=`md5sum $GITATTRIBUTESFILE | cut -d ' ' -f 1`
				HASH2=`md5sum $GITATTRIBUTESFILEMATCH | cut -d ' ' -f 1`
				if [[ $HASH1 == $HASH2 ]]
					then
						$VERBOSE && echo INFO: file $GITATTRIBUTESFILE found at $CURRENTDIR matching $GITATTRIBUTESFILEMATCH
					else
						echo -e ERROR: file $GITATTRIBUTESFILE differs at $CURRENTDIR from $GITATTRIBUTESFILEMATCH
						exit 1
				fi
			else
				echo ERROR: file $GITATTRIBUTESFILE NOT found at $CURRENTDIR
				exit 1
		fi
		
		# check for the presence of a project with same path as repo, i.e. a base project
		if [ -d $CURRENT_REPO ]
			then
				$VERBOSE && echo INFO: base project \"$CURRENT_REPO\" found
			else
				echo ERROR: missing base project \"$CURRENT_REPO\"
				exit 1
		fi
		
		for CURRENT_PROJECT in */
			do
				if [[ -d $CURRENT_PROJECT && $CURRENT_PROJECT != '.' && $CURRENT_PROJECT != '..' ]]
					then
						$VERBOSE && echo ================================================================
						CURRENT_PROJECT=$(echo $CURRENT_PROJECT | cut -d '/' -f 1)
						$VERBOSE && echo INFO: current project is: $CURRENT_PROJECT
						cd $CURRENT_PROJECT
						CURRENTDIR=$CURRENT_REPO/$CURRENT_PROJECT
						$VERBOSE && echo INFO: current dir is: $CURRENTDIR
						
						# check that the project path complies with the naming guidelines
						REGEXP="^($CURRENT_REPO)(.\w+)*"
						if [[ "$CURRENT_PROJECT" =~ $REGEXP ]]
							then
								$VERBOSE && echo INFO: project path complies with naming guidelines
							else
								echo ERROR: project path is $CURRENT_PROJECT but should start with repo name, i.e. $CURRENT_REPO
								exit 1
						fi
						
						# check for the presence of a .project file on project level
						if [ -f $PROJECTFILE ]
							then
								NAMEFROMPROJECT=`grep -m 1 "<name>" .project | sed "s/\s*<name>//; s/<\/name>.*//"`
							else
								echo ERROR: project file $PROJECTFILE NOT found at $CURRENTDIR
								exit 1
						fi
						# check for the presence of a pom.xml file on project level
						if [ ! -f $POMFILE ]
							then
								echo ERROR: $POMFILE NOT found at $CURRENTDIR
								exit 1
						fi
						
						if [ -d $METAINFDIR ]
							then
								cd $METAINFDIR
								CURRENTDIR=$CURRENTDIR/$METAINFDIR
								if [ -f $MANIFESTFILE ]
									then
										CURRENTFILE=$CURRENTDIR'/'$MANIFESTFILE
										$VERBOSE && echo INFO: file $MANIFESTFILE found at $CURRENTDIR
										
										# set variables from MANIFEST.MF
										
										# check that Bundle-Vendor in MANIFEST.MF is set at all
										extractValue $MANIFESTFILE $BUNDLEVENDORLINEIDENTIFIER
										EXTRACTVALUEEXITSTATUS=$?
										
										if [[ $EXTRACTVALUEEXITSTATUS != '0' ]]
											then
												echo 'ERROR: file' $CURRENTFILE 'does not contain expected identifier' \"$BUNDLEVENDORLINEIDENTIFIER\"
												exit $EXTRACTVALUEEXITSTATUS
										fi
										RECEIVEDVENDORSTRING=$VALUE
										
										# check that Bundle-Name in MAINIFEST.MF is set at all
										extractValue $MANIFESTFILE $BUNDLENAMEIDENTIFIER
										EXTRACTVALUEEXITSTATUS=$?
								
										if [[ $EXTRACTVALUEEXITSTATUS != '0' ]]
											then
												echo 'ERROR: file' $CURRENTFILE 'does not contain expected identifier' \"$BUNDLENAMEIDENTIFIER\"
												exit $EXTRACTVALUEEXITSTATUS
										fi
										RECEIVEDNAMESTRING=$VALUE
										
										# check that Bundle-SymbolicName in MAINIFEST.MF is set at all
										extractValue $MANIFESTFILE $BUNDLESYMBOLICNAMEIDENTIFIER
										EXTRACTVALUEEXITSTATUS=$?
								
										if [[ $EXTRACTVALUEEXITSTATUS != '0' ]]
											then
												echo 'ERROR: file' $CURRENTFILE 'does not contain expected identifier' \"$BUNDLESYMBOLICNAMEIDENTIFIER\"
												exit $EXTRACTVALUEEXITSTATUS
										fi
										RECEIVEDSYMBOLICNAMESTRING=$VALUE
										
										$VERBOSE && echo ----------------------------------------------------------------
										$VERBOSE && echo Values read from "$CURRENTFILE"
										$VERBOSE && echo \"$BUNDLENAMEIDENTIFIER\" is: \"$RECEIVEDNAMESTRING\"
										$VERBOSE && echo \"$BUNDLESYMBOLICNAMEIDENTIFIER\" is: \"$RECEIVEDSYMBOLICNAMESTRING\"
										$VERBOSE && echo \"$BUNDLEVENDORLINEIDENTIFIER\" is: \"$RECEIVEDVENDORSTRING\"
										$VERBOSE && echo ----------------------------------------------------------------
										
										
										
										# check that Bundle-Vendor in MANIFEST.MF is set to the expected value
										if [[ "$EXPECTEDVENDORSTRING" != "$RECEIVEDVENDORSTRING" ]]
											then
												echo 'ERROR: expected "'$BUNDLEVENDORLINEIDENTIFIER'" to be "'$EXPECTEDVENDORSTRING'" but found "'$RECEIVEDVENDORSTRING'" in file' $CURRENTFILE
												exit 1
										fi
										
										# check that Bundle-SymbolicName in MANIFEST.MF matches actual project path
										if [[ "$CURRENT_PROJECT" != "$RECEIVEDSYMBOLICNAMESTRING" ]]
											then
												echo ERROR: mismatching project paths "'$CURRENT_PROJECT'" and "'$RECEIVEDSYMBOLICNAMESTRING'"
												exit 1
										fi
										
										# check that Bundle-Name in MANIFEST.MF matches script project name from .project file
										# check that Bundle-SymbolicName in MANIFEST.MF matches code project name from .project file
										DEBUG=`echo "$CURRENT_PROJECT" | grep "$TESTSCRIPTSIDENTIFIER"`
										GREPRESULT=$?
										
										if [[ $GREPRESULT == '0' ]]
											then
												# this is a script project
												if [[ "$NAMEFROMPROJECT" != "$RECEIVEDNAMESTRING" ]]
													then
														echo ERROR: mismatching script project names "'$NAMEFROMPROJECT'" and "'$RECEIVEDNAMESTRING'"
														exit 1
												fi
											else
												# this is a code project
												if [[ "$NAMEFROMPROJECT" != "$RECEIVEDSYMBOLICNAMESTRING" ]]
													then
														echo ERROR: mismatching code project names "'$NAMEFROMPROJECT'" and "'$RECEIVEDSYMBOLICNAMESTRING'"
														exit 1
												fi
										fi
										
										# check that Bundle-Name correctly relates to Bundle-SymbolicName
										
										# check prefixes
										REGEXP="^(org.globaltester)(.\w+)*"
										if [[ "$RECEIVEDSYMBOLICNAMESTRING" =~ $REGEXP ]]
											then
												REGEXP="^($GTIDENTIFIER) .+"
												if [[ "$RECEIVEDNAMESTRING" =~ $REGEXP ]]
													then
														$VERBOSE && echo INFO: this is a $GTIDENTIFIER bundle
													else
														echo ERROR: Bundle-Name \"$RECEIVEDNAMESTRING\" is expected to start with: \"$GTIDENTIFIER\"
														exit 1
												fi
											else
												REGEXP="^(de.persosim)(.\w+)*"
												if [[ "$RECEIVEDSYMBOLICNAMESTRING" =~ $REGEXP ]]
													then
														REGEXP="^($PERSOSIMIDENTIFIER) .+"
														if [[ "$RECEIVEDNAMESTRING" =~ $REGEXP ]]
															then
																$VERBOSE && echo INFO: this is a $PERSOSIMIDENTIFIER bundle
															else
																echo ERROR: Bundle-Name \"$RECEIVEDNAMESTRING\" is expected to start with: \"$PERSOSIMIDENTIFIER\"
																exit 1
														fi
													else
														REGEXP="^(com.hjp)(.\w+)*"
														if [[ "$RECEIVEDSYMBOLICNAMESTRING" =~ $REGEXP ]]
															then
																REGEXP="^(com.hjp.globaltester)(.\w+)*"
																if [[ "$RECEIVEDSYMBOLICNAMESTRING" =~ $REGEXP ]]
																	then
																		REGEXP="^(($GTIDENTIFIER|$EXTENSIONSIDENTIFIER $GTIDENTIFIER) .+|.+ $TESTSPECIDENTIFIER.*)"
																		if [[ "$RECEIVEDNAMESTRING" =~ $REGEXP ]]
																			then
																				$VERBOSE && echo INFO: $RECEIVEDNAMESTRING is a valid name for a com.hjp.globaltester bundle
																			else
																				echo ERROR: $RECEIVEDNAMESTRING is NOT a valid name for a com.hjp.globaltester bundle
																				exit 1
																		fi
																	else
																		REGEXP="^(com.hjp.persosim)(.\w+)*"
																		if [[ "$RECEIVEDSYMBOLICNAMESTRING" =~ $REGEXP ]]
																			then
																				REGEXP="^(($PERSOSIMIDENTIFIER|$EXTENSIONSIDENTIFIER $PERSOSIMIDENTIFIER) .+|.+ $TESTSPECIDENTIFIER.*)"
																				if [[ "$RECEIVEDNAMESTRING" =~ $REGEXP ]]
																					then
																						$VERBOSE && echo INFO: $RECEIVEDNAMESTRING is a valid name for a com.hjp.persosim bundle
																					else
																						echo ERROR: $RECEIVEDNAMESTRING is NOT a valid name for a com.hjp.persosim bundle
																						exit 1
																				fi
																			else
																				$VERBOSE && echo INFO: skipping prefix checks for com.hjp.* bundle
																		fi
																fi
															else
																echo ERROR: Bundle-Name \"$RECEIVEDNAMESTRING\" is of unknown class
																exit 1
														fi
												fi
										fi
										
										# check suffixes
										if [[ "$CURRENT_PROJECT" == "$CURRENT_REPO" ]]
											then
												$VERBOSE && echo INFO: skipping suffix check for base project CP: \"$CURRENT_PROJECT\", BSN: \"$RECEIVEDSYMBOLICNAMESTRING\"
											else
												$VERBOSE && echo INFO: commencing suffix check for non-base project
												MATCH=false
												MATCHEDPATTERN=""
												TARGETPATTERN=""
												for ((i=0; i<${#BSN[*]}; i++));
													do
														MATCHEDPATTERN=${BSN[i]}
														REGEXP=".*\.$MATCHEDPATTERN$"
														if [[ "$RECEIVEDSYMBOLICNAMESTRING" =~ $REGEXP ]]
															then
																MATCH=true
																TARGETPATTERN=${BN[i]}
																break
															else
																MATCHEDPATTERN=""
														fi
													done
												
												if [ $MATCH = true ]
													then
														$VERBOSE && echo INFO: matched pattern is \"MATCHEDPATTERN\" \-\-\> \"$TARGETPATTERN\"
														REGEXP=".* $TARGETPATTERN$"
														if [[ "$RECEIVEDNAMESTRING" =~ $REGEXP ]]
															then
																$VERBOSE && echo INFO: Successful suffix match according to category $MATCHEDPATTERN \-\-\> $TARGETPATTERN
															else
																echo ERROR: Failed suffix match, Bundle-Name \"$RECEIVEDNAMESTRING\" is expected to end with \"$TARGETPATTERN\"
																exit 1
														fi
													else
														echo WARNING: Failed suffix match according to valid categories, BN \"$RECEIVEDNAMESTRING\", BSN \"$RECEIVEDSYMBOLICNAMESTRING\"
												fi
										fi
										
									else
										echo "ERROR: file $MANIFESTFILE NOT found at "$CURRENTDIR
										exit 1
								fi	
								cd ..
						fi
						cd ..	
				fi
			done
		cd ..
fi

$VERBOSE && echo Script finished successfully
