Release process
===============
This document describes the steps necessary to create product releases.

In general the overall development process shall ensure that the current master branch of all repositories is in a consistent state to be built and released at any time. But for a publicly released official version of our products a few extra steps still need to be taken in order to ensure the desired quality.

When all desired features are merged into the master a release can be prepared. Release preparation includes some quality and consistency checks and the assignment of version numbers for all relevant artifacts (depending on included changes). The release build is essentially the same build as during development. Before the build results can be published as official release extensive tests are performed on all artifacts to ensure that they work as expected.

The whole process is implemented in a workflow helper script. That script navigates the user through every step of the process and automates most of the steps. The process description below focuses on the overall process, describes what every step does and provides some hints for manual actions needed by the user. Although theoretically possible it is not advisable to build a release based only on the description below without the workflow script.

1. __Check open branches__  
Ensure that all required branches are merged (and removed on the remotes)

1. __Consistency checks__  
Not yet implemented. In the near future we will add some checks that ensure consistent naming of projects, bundles etc.
Also we do handle some cloned testscripts for different customer groups and plan to implement a script that checks for mutual changes to ensure that both products contain all relevant bugfixes. 

1. __Update repository changelogs__  
The CHANGELOG files in each repository reflect the latest changes to each repo. Their content is manually condensed from the git commit history. In general remove all "maintenance" commits and combine the remaining ones to a concise bullet list. The workflow helper will present a preformated list with all commit messages so it can be easily condensed.  
According to the changes integrated into the new release make sure that a new proper version number is set in the first line of the CHANGELOG. It should represent how extensive the changes are (bugfixes, new features etc.). This version will be used throughout the later process to ensure that all relevant files are adjusted correctly.  
The workflow helper will provide the option to commit the prepared changelogs to ensure that no further changes during the build will break the results of this tedious task. Unless you have a very good reason to not commit them just stay with the default.

1. __Check product list__  
While the workflow script generates a complete list of available products from the current workspace it is not always required to release all products at once. So ensure that all products you want to release are contained in the presented temporary product list. Products you don't want to release as part of this process can be easily removed and will no longer be considered for that particular run. 

1. __Update product changelogs__  
The product changelog is essentially the CHANGELOG file of the repository that contains the product defining bundle. As such it already was updated in the earlier step. But as the product contains more bundles the significant changes of downstream bundles shall be integrated into the product changelog as well.  
The workflow helper again generates complete list, based on the CHANGELOG contents of the included bundles. This needs to be condensed manually, e.g. changes not related to the product at hand shall be removed.
Again you are prompted to commit those changes and shall do so unless you have very good reasons not to.

1. __Transfer version numbers__  
The version numbers assigned in the repository CHANGELOG must be mirrored to the several Eclipse relevant files (e.g. MANIFEST.MF, feature.xml and *.product). For GlobalTester scripts they even need to be copied to every single testcase (together with the release date).

1. __Update checksums__  
GlobalTester test script projects contain a checksum that ensures that they are genuine. This checksums need to be updated for every release right after updating version and date information within the testcases. The process to do this is completely automated.






1. __Create consolidated aggregator build__  
To ensure a well documented build we create a temporary build directory next to our existing projects.
As the following steps need to be repeated for every product and several products rely on similar bundles those would get processed several times. To avoid this it is advisable to perform those steps only once on a consolidated aggregator. This aggregator simply combines all module dependencies of the product aggregators into one large aggregator project, which is stored in the temporary build directory and later used for every exectuion.

1. __Update POM versions__  
The new version numbers assigned in the previous steps need to be populated to the different pom.xml files in order to achieve a consistent maven build. This requires updating the POM files for every project and additionally updating the version constraints in pom dependencies. This can be handled by Tycho, which unfortunately implies a significant overhead caused by the Tycho dependency resolution process. The impact of this drawback can be reduced a little by considering every bundle only once within the common aggregator.
		mvn org.eclipse.tycho:tycho-versions-plugin:update-pom
1. __Build the desired products__  
If you followed the steps above this step simply boils down to a maven build of the consolidated aggregator in your temporary build dir.

1. __Collect build artifacts__  
The maven build generates several artifacts in the target folders of the respective modules. All these artifacts need to be collected into a subfolder of your builddir. This allows easier access to the needed artifacts for testing and publishing later.

1. __Generate test documentation__  
Beside the automated tests that were already executed as part of the build every product and bundle can define their own manual test steps to be performed on the final product. To document the test process the releaseTest.md files are structured in a way to be used as easy check lists. Consolidate all releaseTest.md files from all projects included in the build into one file, generate html and print a copy. The printed checklist assists while executing the tests and can later be attached to the release documentation.

1. __Test the build__  
Ensure that all product artifacts can be used as intended. Each project may define integration tests within their specific releaseTest.md files, so check those and make sure to cover all the tests mentioned there.  
If building releases to be published make sure to perform the tests on different supported platforms (operating system, Java version, Eclipse version). As most product tests rely on other products this can be simplified by doing cross tests in different combinations.

1. __Generate release documentation__  
In order to be able to look back a few releases it is a good think to document the release process and results. This step generates a short overview of the Ws about the release (e.g. Who, When, What). This overview shall be printed and archived together with the latest test documentation

1. __Tag repositories__  
As all bundles are finally tested all repositorys shall be version tagged according to the new version defined in the earlier steps.

1. __Tag products__  
As all products are finally tested all the products (and all included projects) shall be version tagged according to the product versions just released. This allows for every product to go back to the consistent state to repeat a build or incorporate hotfixes etc.

1. __Publish release__  
Finally the release is completely done. Not quite! Until now we have not actually released anything. So release the new artifacts into the public.  
This step is not yet covered by the workflow script but should include:
    * uploading the release to public repos/website etc.
    * informing customers about the new version (the CHANGELOG files are a great basis for this)
    * pushing release commits and tags to relevant repos (HJP servers, GitHub) 


<p style="page-break-after: always"/>
