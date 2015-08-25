Release process
===============
This document describes the steps necessary to create product releases.

Check repository states
--------------------------
Before starting the release build it is wise to perform some basic check on the projects included in the build:

1. __Check open branches__  
Ensure that all required branches are merged (and removed on the remotes)
1. __Check version numbers__  
According to the changes integrated in the new release make sure that a new proper version number is set. It should represent how extensive the changes are (bugfixes, new features etc.).
1. __Check documentation__  
Make sure that the newly introduced features are properly documented in the code (via Javadoc) and readme files.

Build the product
-----------------
Call 'mvn clean verify' within the appropriate releng project. This will generate the product artifacts in the appropriate target folders. We provide several releng projects (at least one for every single product and an overall com.hjp.releng project), depending on which products you have access to you won`t be able to build all of them.

Test it
-------
Ensure that all product artifacts can be used as intended. Most Product releng-projects will define some kind of integration tests within their specific release.md files, so check those and make sure to cover all the tests mentioned there.

If building releases to be published make sure to perform the tests on different supported platforms (operating system, Java version, Eclipse version). As most products tests rely on other products this can be simplified by doing cross tests in different combinations.

<p style="page-break-after: always"/>
