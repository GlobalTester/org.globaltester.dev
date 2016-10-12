Setup development environment
=============================
In order to setup a fresh build area create an empty directory and cd into it.

The repositories needed to build can be checked out manually or assisted by a script in this repository. 

Manual checkout means that you will have to clone a product repository (the names can be found in the `org.globaltester.dev/projects.md` file in this repository) and use the pom.xml file of the contained *.releng folder to find all needed repositories for this product. Those repositories need to be checked out for the build to succeed. Additionally you should clone this repository "`org.globaltester.dev`" for reference since it contains useful documentation and tools. 

Script assisted checkout can be done by using the scripts found in `org.globaltester.dev.tools` in this repository. The script runs under unix alike systems (Cygwin and several Linux distributions have been tested) and was developed to be executed in a bash shell. It takes the product repository and source to be used as a parameter and automatically checks out all needed repositories. This script is provided as is and was developed as a helper for our internal development. Thus it is not thoroughly tested and should be used with caution. For usage refer to the output of calling the scripts with `--help`.

Depending on your connectivity to the providing servers this might take some time.
Congratulations, you have a complete working copy.

Building products
-----------------
We use Maven as primary build tool so you will find a maven POM file within almost every project.
In order to build specific projects change to the appropriate directory and build them with
`mvn clean verify`
This should work for all `*.releng` projects that build the specific products. The project `com.hjp.internal.releng` builds all products in one build (but is only appropriate if you really have access to all products, which you most probably won't have unless you work at secunet).

Setup Eclipse
-------------
If you followed the instructions above you can easily import all projects in your Eclipse workspace. Just select "Import... > General > Existing Projects into Workspace". Follow the wizard, you can select the root directory you cloned repositories to, this will detect all relevant projects. Make sure not to copy them, this will allow eGit to operate on your existing repository clone.

We were used to use Eclipse Standard and moved to Eclipse IDE for Eclipse Committers, but you can use any edition you like. Here`s a list of features you might want to have installed in order to use full integration.
- Java Development Tools, as most projects are Java projects
- Plug-in Development Environment, as most things we do are Eclipse Plug-ins
- eGit, for version control
- e4 Tools Developer Resources, for convenient editing of E4 resources
- m2e, Maven Integration for Eclipse, if you want to trigger the maven build from within the IDE
- Windows users should make sure that correct line endings are used (Preferences->Workspace->choose Unix line endings)

Upgrading
---------
Most changes can be fetched by simple git operations within the repositories.
Sometimes situations arise where new bundles are added, existing projects are renamed or removed. To deal with situations like this you should be prepared to rerun the checkout script using the corresponding parameter to ignore already existing repositories (which will then clone new repositories), add new projects to your Eclipse workspace and maybe remove orphaned projects manually.

