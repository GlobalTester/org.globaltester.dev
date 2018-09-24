#!/bin/bash
# must be called from root directory
. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh

COVERAGE_POM=$1
if [ ! -f "$COVERAGE_POM" ]
then
	echo "Coverage POM not found $RELENG_POM"
	exit 1;
fi

if [ -n "$2" ]
then
	RELENG_POM=$2
else
	RELENG_POM=`dirname "$COVERAGE_POM"`
	RELENG_POM=`readlink -f "$RELENG_POM"/../*.releng/pom.xml`
fi

if [ ! -f "$RELENG_POM" ]
then
	echo "Releng POM not found $RELENG_POM"
	exit 1;
fi

#remove previous dependencies
sed -i -e '/<dependencies>/,$d' $COVERAGE_POM
echo "  <dependencies>" >> $COVERAGE_POM

#iterate modules
grep "<module>" "$RELENG_POM" | while read -r MODULE ; do
	BUNDLE=$(echo "$MODULE" | sed 's|</module>.*||; s|.*/||')

	#do not include parent modules in coverage report
	if [[ "$BUNDLE" =~ org\.globaltester\.parent.* ]]; then
		continue
	fi

	#do not include coverage, site, product and deploy modules in coverage report
	if [[ "$BUNDLE" =~ .*\.((coverage)|(site)|(product)|(deploy))$ ]]; then
		continue
	fi

	#get group id for BUNDLE
	GROUP_ID=`getGroupIdForBundle $BUNDLE`

	#get artifact version
	ARTIFACT_VERSION=`getCurrentVersionFromChangeLog $BUNDLE`
	
	#define the scope
	SCOPE="compile"
	if [[ "$BUNDLE" =~ .*\.((test)|(integrationtest)|(crossover)|(rcptt))$ ]]; then
		SCOPE="test"
	fi


	#write the dependency to COVERAGE_POM
	echo "    <dependency>" >> $COVERAGE_POM
	echo "      <groupId>$GROUP_ID</groupId>" >> $COVERAGE_POM
	echo "      <artifactId>$BUNDLE</artifactId>" >> $COVERAGE_POM
	echo "      <version>$ARTIFACT_VERSION-SNAPSHOT</version>" >> $COVERAGE_POM
	echo "      <scope>$SCOPE</scope>" >> $COVERAGE_POM
	echo "    </dependency>" >> $COVERAGE_POM
done


#finish file
echo "  </dependencies>" >> $COVERAGE_POM
echo >> $COVERAGE_POM
echo "</project>" >> $COVERAGE_POM

