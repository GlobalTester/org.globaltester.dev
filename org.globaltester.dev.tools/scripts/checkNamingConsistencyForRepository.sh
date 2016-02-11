#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh
set +e

METAINFDIR='META-INF'
MANIFESTFILE='MANIFEST.MF'
PROJECTFILE='.project'

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
#</GIT-specific files>

#<HJP-specific identifiers>
GTIDENTIFIER="GT"
PERSOSIMIDENTIFIER="PersoSim"
EXTENSIONSIDENTIFIER="Extensions to"
TESTSPECIDENTIFIER="TestSpecification"
#</HJP-specific identifiers>

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

for CURRENT_REPO in */
	do
		if [[ -d $CURRENT_REPO && $CURRENT_REPO != '.' && $CURRENT_REPO != '..' ]]
			then
				echo "################################################################"
				CURRENT_REPO=$(echo $CURRENT_REPO | cut -d '/' -f 1)
				echo INFO: current repo is: $CURRENT_REPO
				cd $CURRENT_REPO
				CURRENTDIR=$CURRENT_REPO
				echo INFO: current dir is: $CURRENTDIR
				
				# check for the presence of a .gitignore file on repository level
				if [ -f $GITIGNOREFILE ]
					then
						echo INFO: file $GITIGNOREFILE found at $CURRENTDIR "as expected (content currently unchecked)"
					else
						echo ERROR: file $GITIGNOREFILE NOT found at $CURRENTDIR
						exit 1
				fi
				
				# check for the presence of a .gitattributes file on repository level
				if [ -f $GITATTRIBUTESFILE ]
					then
						echo INFO: file $GITATTRIBUTESFILE found at $CURRENTDIR "as expected (content currently unchecked)"
					else
						echo ERROR: file $GITATTRIBUTESFILE NOT found at $CURRENTDIR
						exit 1
				fi
				
				for CURRENT_PROJECT in */
					do
						if [[ -d $CURRENT_PROJECT && $CURRENT_PROJECT != '.' && $CURRENT_PROJECT != '..' ]]
							then
								echo ================================================================
								CURRENT_PROJECT=$(echo $CURRENT_PROJECT | cut -d '/' -f 1)
								echo INFO: current project is: $CURRENT_PROJECT
								cd $CURRENT_PROJECT
								CURRENTDIR=$CURRENT_REPO/$CURRENT_PROJECT
								echo INFO: current dir is: $CURRENTDIR
								
								# check that the project path complies with the naming guidelines
								REGEXP="^($CURRENT_REPO)(.\w+)*"
								if [[ "$CURRENT_PROJECT" =~ $REGEXP ]]
									then
										echo INFO: project path complies with naming guidelines
									else
										echo ERROR: project path is $CURRENT_PROJECT but should start with repo name, i.e. $CURRENT_REPO
										exit 1
								fi
								
								# check for the presence of a .project file on project level
								if [ -f $PROJECTFILE ]
									then
										NAMELINE=`grep -m 1 'name' $PROJECTFILE | sed 's|^\s*||'`
										NAMEFROMPROJECT=$(echo $NAMELINE | cut -d '>' -f 2- | cut -d '<' -f 1)
									else
										echo ERROR: project file $PROJECTFILE NOT found at $CURRENTDIR
										exit 1
								fi
								
								if [ -d $METAINFDIR ]
									then
										cd $METAINFDIR
										CURRENTDIR=$CURRENTDIR/$METAINFDIR
										if [ -f $MANIFESTFILE ]
											then
												CURRENTFILE=$CURRENTDIR'/'$MANIFESTFILE
												echo INFO: file $MANIFESTFILE found at $CURRENTDIR
												
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
												
												echo ----------------------------------------------------------------
												echo Values read from "$CURRENTFILE"
												echo \"$BUNDLENAMEIDENTIFIER\" is: \"$RECEIVEDNAMESTRING\"
												echo \"$BUNDLESYMBOLICNAMEIDENTIFIER\" is: \"$RECEIVEDSYMBOLICNAMESTRING\"
												echo \"$BUNDLEVENDORLINEIDENTIFIER\" is: \"$RECEIVEDVENDORSTRING\"
												echo ----------------------------------------------------------------
												
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
												REGEXP="^(org.globaltester)(.\w+)*"
												if [[ "$RECEIVEDSYMBOLICNAMESTRING" =~ $REGEXP ]]
													then
														REGEXP="^($GTIDENTIFIER) .+"
														if [[ "$RECEIVEDNAMESTRING" =~ $REGEXP ]]
															then
																echo INFO: this is a $GTIDENTIFIER bundle
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
																		echo INFO: this is a $PERSOSIMIDENTIFIER bundle
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
																						echo INFO: $RECEIVEDNAMESTRING is a valid name for a com.hjp.globaltester bundle
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
																								echo INFO: $RECEIVEDNAMESTRING is a valid name for a com.hjp.persosim bundle
																							else
																								echo ERROR: $RECEIVEDNAMESTRING is NOT a valid name for a com.hjp.persosim bundle
																								exit 1
																						fi
																					else
																						echo WARNING: unchecked com.hjp.* bundle
																				fi
																		fi
																	else
																		echo ERROR: Bundle-Name \"$RECEIVEDNAMESTRING\" is of unknown class
																		exit 1
																fi
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
	done

echo Script finished successfully