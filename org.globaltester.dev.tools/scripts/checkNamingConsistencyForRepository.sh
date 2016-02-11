#!/bin/bash
# must be called from root directory for all repos
set -e
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh
set +e

METAINFDIR='META-INF'
MANIFESTFILE='MANIFEST.MF'
PROJECTFILE='.project'

#<MANIFEST.MF-specific identifier>
BUNDLENAMEIDENTIFIER="Bundle-Name"
BUNDLESYMBOLICNAMEIDENTIFIER="Bundle-SymbolicName"
BUNDLEVENDORLINEIDENTIFIER="Bundle-Vendor"
#</MANIFEST.MF-specific identifier>

EXPECTEDVENDORSTRING="HJP Consulting GmbH"
TESTSCRIPTSIDENTIFIER="testscripts"

#<GIT-specific files>
GITIGNOREFILE='.gitignore'
GITATTRIBUTESFILE='.gitattributes'
#</GIT-specific files>

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
	echo 'INFO: value of "'$IDENTIFIER'" is: '$VALUE
	
	return 0
}

for CURRENT_REPO in */
	do
		if [[ -d $CURRENT_REPO && $CURRENT_REPO != '.' && $CURRENT_REPO != '..' ]]
			then
				CURRENT_REPO=$(echo $CURRENT_REPO | cut -d '/' -f 1)
				echo INFO: current repo is: $CURRENT_REPO
				cd $CURRENT_REPO
				CURRENTDIR=$CURRENT_REPO
				echo INFO: current dir is: $CURRENTDIR
				
				# check for the presence of a .gitignore file on repository level
				if [ -f $GITIGNOREFILE ]
					then
						echo INFO: file $GITIGNOREFILE found at $CURRENTDIR as expected
					else
						echo ERROR: file $GITIGNOREFILE NOT found at $CURRENTDIR
						#exit 1
				fi
				
				for CURRENT_PROJECT in */
					do
						if [[ -d $CURRENT_PROJECT && $CURRENT_PROJECT != '.' && $CURRENT_PROJECT != '..' ]]
							then
								CURRENT_PROJECT=$(echo $CURRENT_PROJECT | cut -d '/' -f 1)
								echo INFO: current project is: $CURRENT_PROJECT
								cd $CURRENT_PROJECT
								CURRENTDIR=$CURRENT_REPO/$CURRENT_PROJECT
								echo INFO: current dir is: $CURRENTDIR
								
								# check that the project path complies with the naming guidelines
								REGEXP="^($CURRENT_REPO)(.\w*)*"
								if [[ "${CURRENT_PROJECT,,}" =~ $REGEXP ]]
									then
										echo INFO: project path complies with naming guidelines
									else
										echo ERROR: project path is $CURRENT_PROJECT but should start with repo name, i.e. $CURRENT_REPO
										#exit 1
								fi
								
								# check for the presence of a .project file on project level
								if [ -f $PROJECTFILE ]
									then
										NAMELINE=`grep -m 1 'name' $PROJECTFILE | sed 's|^\s*||'`
										NAMEFROMPROJECT=$(echo $NAMELINE | cut -d '>' -f 2- | cut -d '<' -f 1)
									else
										echo ERROR: project file $PROJECTFILE NOT found at $CURRENTDIR
										#exit 1
								fi
								
								if [ -d $METAINFDIR ]
									then
										cd $METAINFDIR
										CURRENTDIR=$CURRENTDIR/$METAINFDIR
										if [ -f $MANIFESTFILE ]
											then
												CURRENTFILE=$CURRENTDIR'/'$MANIFESTFILE
												echo INFO: file $MANIFESTFILE found at $CURRENTDIR
												
												# check that Bundle-Vendor in MANIFEST.MF is set at all
												extractValue $MANIFESTFILE $BUNDLEVENDORLINEIDENTIFIER
												EXTRACTVALUEEXITSTATUS=$?
												
												if [[ $EXTRACTVALUEEXITSTATUS != '0' ]]
													then
														echo 'ERROR: file' $CURRENTFILE 'does not contain expected identifier' \"$BUNDLEVENDORLINEIDENTIFIER\"
														#exit $EXTRACTVALUEEXITSTATUS
												fi
												
												RECEIVEDVENDORSTRING=$VALUE
												echo \"$BUNDLEVENDORLINEIDENTIFIER\" is: \"$RECEIVEDVENDORSTRING\"
												
												# check that Bundle-Vendor in MANIFEST.MF is set to the expected value
												if [[ "$EXPECTEDVENDORSTRING" != "$RECEIVEDVENDORSTRING" ]]
													then
														echo 'ERROR: expected "'$BUNDLEVENDORLINEIDENTIFIER'" to be "'$EXPECTEDVENDORSTRING'" but found "'$RECEIVEDVENDORSTRING'" in file' $CURRENTFILE
														#exit 1
												fi
												
												# check that Bundle-SymbolicName in MAINIFEST.MF matches the actual project path
												extractValue $MANIFESTFILE $BUNDLESYMBOLICNAMEIDENTIFIER
												EXTRACTVALUEEXITSTATUS=$?
										
												if [[ $EXTRACTVALUEEXITSTATUS != '0' ]]
													then
														echo 'ERROR: file' $CURRENTFILE 'does not contain expected identifier' \"$BUNDLESYMBOLICNAMEIDENTIFIER\"
														#exit $EXTRACTVALUEEXITSTATUS
												fi
										
												RECEIVEDSYMBOLICNAMESTRING=$VALUE
												PROJECTPATH=$CURRENT_PROJECT
												echo path: $PROJECTPATH
												if [[ "$PROJECTPATH" != "$RECEIVEDSYMBOLICNAMESTRING" ]]
													then
														echo ERROR: mismatching project paths "'$PROJECTPATH'" and "'$RECEIVEDSYMBOLICNAMESTRING'"
														#exit 1
												fi
												
												# check that Bundle-SymbolicName in MANIFEST.MF matches project name from .project
												extractValue $MANIFESTFILE $BUNDLENAMEIDENTIFIER
												EXTRACTVALUEEXITSTATUS=$?
										
												if [[ $EXTRACTVALUEEXITSTATUS != '0' ]]
													then
														echo 'ERROR: file' $CURRENTFILE 'does not contain expected identifier' \"$BUNDLENAMEIDENTIFIER\"
														exit $EXTRACTVALUEEXITSTATUS
												fi
										
												RECEIVEDNAMESTRING=$VALUE
												
												DEBUG=`echo "$PROJECTPATH" | grep "$TESTSCRIPTSIDENTIFIER"`
												GREPRESULT=$?
												
												if [[ $GREPRESULT == '0' ]]
													then
														if [[ "$NAMEFROMPROJECT" != "$RECEIVEDNAMESTRING" ]]
															then
																echo ERROR: mismatching script project names "'$NAMEFROMPROJECT'" and "'$RECEIVEDNAMESTRING'"
																#exit 1
														fi
													else
														if [[ "$NAMEFROMPROJECT" != "$RECEIVEDSYMBOLICNAMESTRING" ]]
															then
																echo ERROR: mismatching code project names "'$NAMEFROMPROJECT'" and "'$RECEIVEDSYMBOLICNAMESTRING'"
																#exit 1
														fi
												fi	
												
											else
												echo "ERROR: file $MANIFESTFILE NOT found at "$CURRENTDIR
												#exit 1
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