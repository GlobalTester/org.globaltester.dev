Release process
===============
This document describes the steps necessary to create product releases.

Prepare the build
-----------------
Before starting the release build some basic checks and final touches should be performed on the projects included in the build:

1. __Check open branches__  
Ensure that all required branches are merged (and removed on the remotes)

		#find branches that are not merged into current branch
		curDir=`pwd`; for curProj in */; do cd "$curProj";echo -en "\e[36m" ; pwd; echo -en "\e[0m"; git branch -al --no-merged ; cd $curDir; done

1. __Check documentation__  
Make sure that the newly introduced features are properly documented in the code (via Javadoc) and readme files.

1. __Check/assign version numbers__  
According to the changes integrated in the new release make sure that a new proper version numbers are set. It should represent how extensive the changes are (bugfixes, new features etc.).
For code bundles they are defined in the respecitve MANIFEST.MF files (and mirrored in the pom.xml). For script bundles they are primarily maintained within the Readme.txt and copied from there to all places where they need to be consistent (e.g. testcases or manifest files), see the following section for more details.

1. __Derive dependent artifacts__  
Currently some build artifacts depend on others and are synchronized manually. At the moment this is mostly related to script bundles.
First to mention are script packages that are mostly a subset of others (e.g. GT Scripts eID client). These are present in the repositories and contain their own metadata. In order to update these with the full content you need to execute the appropriate executable class from Build Scripts GT.
Although not strictly required for working script bundles but essential for consistent artifacts there is a second step to go in order to build completely correct script bundles: synchronize version numbers, release dates and integrity checksums between all relevant files. As mentioned in the section before these values are maintained within the readme files and synchronized from there. within `Build scripts GT` exists an ANT build file that handles all this synchronization tasks for all script projects. The result can be used for the build and later be added and committed to the repository.

Build the release documentation
-------------------------------
In order to document the release (and its tests in the following section) we like to generate an overview of what we just did and a checklist for the following tests:


		# collect version information
		VERSIONTMP=`mktemp`
		BUNDLEVERSIONS=`mktemp`
		VERSIONFILE="com.hjp.releng/com.hjp.releng/versions.md"
		
		#collect and format bundle versions
		grep -h -E "Bundle-((Symb)|(Vers))" ./*/*/META-INF/MANIFEST.MF | paste - - | sed -e "s/Bundle-SymbolicName:\s*//;s/Bundle-Version:\s*//;s/;singleton:=true//;s/^/\t\t/" > $VERSIONTMP
		while read LINE; do   printf  "%-60s %s\n" $LINE; done < $VERSIONTMP >$BUNDLEVERSIONS
		sort -o $BUNDLEVERSIONS $BUNDLEVERSIONS
		cat $BUNDLEVERSIONS | tr " " "-" > $VERSIONTMP
		cp $VERSIONTMP $BUNDLEVERSIONS
		sed -i -e "s/\([^-]\)-/\1 /;s/-\([^-]\)/ \1/" $BUNDLEVERSIONS
		
		#concat all parts of version information
		echo -e "Bundle versions\n---------------"> $VERSIONFILE
		sed -e "s/^/\t\t/" $BUNDLEVERSIONS >> $VERSIONFILE
		echo -e "\n<p style=\"page-break-after: always\"/>" >> $VERSIONFILE
		
		# aggregate all files and generate html
		MDFILE=`mktemp`
		echo -e "Release overview\n================"> $MDFILE
		echo -e "Environment information\n-----------------"> $MDFILE
		echo -e "Date: \`" `date  +%Y-%m-%d` "\`  ">> $MDFILE
		echo -e "Executed by: \`" `id -u -n` "\`  " >> $MDFILE
		echo -e "Machine: \`" `uname -a` "\`  " >> $MDFILE
		echo -e "Java: \`" `java -version 2>&1 | grep build` "\`  " >> $MDFILE
		echo -e "\n" >> $MDFILE
		cat $VERSIONFILE >> $MDFILE
		find ./ -name releaseTests.md -exec cat {} >> $MDFILE \;
		cat com.hjp.internal/com.hjp.internal.releng/samples/*.md >> $MDFILE
		
		# generate printable html 
		HTMLFILE=`mktemp`
		markdown $MDFILE > $HTMLFILE
		firefox --new-window $HTMLFILE


Build the product(s)
--------------------
Call 'mvn clean verify' within the appropriate releng project. This will generate the product artifacts in the appropriate target folders. We provide several releng projects (at least one for every single product and an overall com.hjp.releng project), depending on which products you have access to you won`t be able to build all of them.

		# build the product(s)
		cd <releng project>
		mvn clean verify
		
		#collect build artifacts and push them to shared/public
		find . \( -name *site*.zip -o -name *gt_scripts*.zip -o -name *product-*.zip \)  -exec cp {} ~/tmp/releasetest \;
		

Test it
-------
Ensure that all product artifacts can be used as intended. Each project may define integration tests within their specific releaseTest.md files, so check those and make sure to cover all the tests mentioned there.

If building releases to be published make sure to perform the tests on different supported platforms (operating system, Java version, Eclipse version). As most products tests rely on other products this can be simplified by doing cross tests in different combinations.

<p style="page-break-after: always"/>
