Setup development environment
=============================
In order to setup a fresh build area create an empty directory and cd into it.
From there clone com.hjp.releng:
git clone git@git.hjp-consulting.com:com.hjp.releng

From the same directory execute the checkout script(s) appropriate for you.
'./com.hjp.releng/com.hjp.releng/checkout/<project>.bat'
If you use scripts for products you are not a member of access to some of the repositories might be denied.
These scripts are shell/OS independent as long as you have git on your PATH.

Depending on your connectivity to the providing servers this might take some time.
Gratulations, your have a complete workingcopy.


Building products
-----------------
We use Maven as primary build tool so you will find a maven POM file within almost every project.
In order to build specific projects change to the appropriate directory and build them with
mvn clean verify
This should work for all *.releng projects that build the specific products. The project com.hjp.releng builds all products in one build (but is only appropriate if you really have access to all products, which you most probable won`t have unless you work at HJP).

Setup Eclipse
-------------
If you followed the instructions above you can easily import all projects in your Eclipse workspace. Just select "Import... > General > Existing Projects into Workspace". Follow the wizard, you can select the root directory you cloned repositories to, this will detect all relevant projects. Make sure not to copy them, this will allow eGit to operate on your existing repository clone.

We were used to use Eclipse Standard and moved to Eclipse IDE for Eclipse Committers, but you can use any edition you like. Here`s a list of features you might want to have installed in order to use full integration.
- Java Development Tools, as most projects are Java projects
- Plug-in Development Environment, as most things we do are Eclipse Plug-ins
- eGit, for version control
- e4 Tools Developer Resources, for convenient editing of E4 resources
- m2e, Maven Integration for Eclipse, if you want to trigger the maven build from within the IDE

Upgrading
---------
Most changes can be fetched by simple git operations within the repositories.
Sometimes situations arise where new bundles are added, existing projects are renamed or removed. To deal with situations like this you should be prepared to rerun the checkout script (which will clone new repositories), add new projects to your Eclipse workspace and maybe remove orphaned projects manually.

