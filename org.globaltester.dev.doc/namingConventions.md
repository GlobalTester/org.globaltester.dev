Naming conventions
==================
This file documents naming conventions to be obeyed when creating new or modifying existing repositories, projects or bundles.

These conventions can be checked using the scripts provided within `org.globaltester.dev.tools`. These scripts are also integrated in the overall release workflow.

Naming of main projects and repositories
----------------------------------------
Whenever code is created that does not properly fit into one of our existing projects a new project (and in most cases a new repository) needs to be created.

In essence our project names (and resulting repository names) consist of a prefix that defines publicity (and a little association to existing projects) and a specific part.

The prefix shall be defined as one of the exisitng following categories: 

`com.secunet`  
This category denotes everything that is the closed source property of secunet Security Networks AG.
If something is not explicitly determined to be open source it is to be placed in this category.

`de.persosim`  
This category denotes everything that is part of the open source branch of the PersoSim project.
If something is explicitly open source and only usable within the context of this category it is to be placed here.

`org.globaltester`  
This category denotes everything that is part of the open source GlobalTester universe.
If something is explicitly open source and does not belong to one of the other categories it is to be placed here.

The following segments are almost free but should resemble the product it is part of and its general purpose. Also keep in mind that the project name shall be structured according to Java package names (as we target to provide packages only in bundles that imply this by name.

The name of a repository shall be reflected in the name of its directory in the file system. Within that repository the main project/bundle is hosted in its own subdirectory of the same name. This allows the repository to host all related/affilitate projects (see next section)


Example:  
The repository `com.secunet.persosim.simulator.protocols.ca3` describes a closed source addition (`com.secunet`) to the open source _PersoSim_ project.
Furthermore it is part of PersoSim's `simulator` core adding a certain protocol named `ca3`.

Affiliate projects
------------------
Together with every project we might define several affiliate projects that host code/artifacts related to that project but not essentially part of it, e.g. test or documentation. Those affiliate projects are hosted within the same repository and use specific suffixes to differentiate them.

As a rule of thumb affiliate projects should not add to much external dependencies (besides those implied by their specific use e.g. o.e.help for doc bundles). This allows importing of affiliate projects into a common workspace without adding new dependency errors.

Here is a complete list of the known suffixes currently in use:

* deploy [Deploy]
	project to build a product with certain installed features
* doc [Doc]
	documentation on the project, e.g. Eclipse online help
* feature [Feature]
	Eclipse feature project that allows the build
* integrationtest [Integration Test]
	automated integration tests for the main project, e.g. automated tests run through Maven/Tycho/Surefire
* product [Product]
	Eclipse product definition project
* releng [Releng]
	release engineering project. Essentially define release build processes and documentation for building and testing a product
* sample [Sample]
	sample code project, e.g. how to integrate or interact with the main project
* scripts [Scripts]
	packaging of GlobalTester test scripts related to the product defined by the main project
* site [Site]
	Eclipse update site project
* test [Test]
	unit tests for the main project, e.g. run through Maven/Surefire
* tools [Tools]
	tools related to the main project, this might be scripts or code fragments which may be useful for developing, testing or releasing the projects
* ui [UI]
	user interface specific code, mainly separated in order to allow headless use of the main project
* ui.test [UI Test]
	unit tests for the ui project, e.g. run through Maven/Surefire
* ui.integrationtest [UI Integration Test]
	automated integration tests for the ui project, e.g. automated tests run through Maven/Tycho/Surefire

Exceptions and/or modifications to this list are possible in general but should at least be thoroughly discussed by all developers.
For example we currently have several projects that are combined into one repository while not strictly being affiliate projects according to the above definition (e.g. `o.g.cryptoprovider.bc` and `o.g.c.sc`). Legit reasons to do so may be very small related projects that wont change much in the future, interchangeable third party libraries that we just package or legacy code that will get removed in the near future.

Affiliate repos
------------------
While affiliate projects (as described in the previous section) shall not add additional dependencies the need arises to define some kind of related projects with (severe) additional dependencies. These should be separated into their own repository (with their own affiliate projects as appropriate). That allows users to in-/exclude them from their checkout/workspace as needed.  

Here is a complete list of the known suffixes currently in use:
* crossover [CrossOver]
	repo that defines crossover tests between different products. Contains a integrationtest bundles that test several aspects of the base product by using other projects from the GlobalTester universe. This implies that these might require access to several repos from other products.

Bundle-Name and Bundle-SymbolicName
-----------------------------------
Most of our projects are OSGi bundles so they define two additional values that should be kept in sync with the repo and project names: `Bundle-Name` and `Bundle-SymbolicName`. Both are defined in the bundles `META-INF/MANIFEST.MF` file.

The `Bundle-SymbolicName` must match the directory name of the project. This is an essential assumption made in several steps/tools throughout our build process. 

The `Bundle-Name` value must be a human readable representaion of the `Bundle-SymbolicName`. There is no techincal restriction in the selection of a `Bundle-Name` but in order to keep name consistent throughout all our projects we define some matching rules between `Bundle-Name` and `Bundle-SymbolicName`:

* if `Bundle-SymbolicName` starts with `org.globaltester`, Bundle-Name is to start with "GT"
* if `Bundle-SymbolicName` starts with `de.eprsosim`, Bundle-Name is to start with "PersoSim"
* if `Bundle-SymbolicName` starts with `com.secunet.globaltester`, Bundle-Name is to start with "GT" or "Extensions to GT"
* if `Bundle-SymbolicName` starts with `com.secunet.persosim`, Bundle-Name is to start with "PersoSim" or "Extensions to PersoSim"
* The suffix for affiliate projects shall be its human readable representation listed in [] behind it in the above listing.

Project name within workspace
-----------------------------
The actual project name within Eclipse workspace is defined in the .project file of each project.
For the actual value of this we differentiate between "code" and "script" projects.
The project name of code projects is to match the project's directory name and Bundle-SymbolicName.
For script projects the project name is to be the human readable representation (essentially the Bundle-Name, see above).

