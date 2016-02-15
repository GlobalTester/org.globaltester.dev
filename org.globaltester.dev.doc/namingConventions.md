Naming conventions
==================

This file documents naming conventions to be obeyed when creating new or modifying existing repositories, projects or bundles.
This conventions can be checked using the script checkNamingConsistencyForRepository.sh within org.globaltester.dev/org.globaltester.dev.tools/scripts executed from your git root directory with "bash" or "bash -x" for additional debug information.

Repository names
----------------

When creating a new repository it first of all must be given a name.
The name of a repository is represented by the name of its directory in the file system.
It must be allocated to one of the following already existing categories:
* com.hjp
* de.persosim
* org.globaltester

_com.hjp_
This category denotes everything that is the closed source property of HJP Consulting GmbH.
If something is not explicitly determined to be open source it is to be placed in this category.

_de.persosim_
This category denotes everything that is part of the open source branch of the PersoSim project.
If something is explicitly open source and only usable within the context of this category it is to be placed here.

_org.globaltester_
This category denotes everything that is part of the open source GlobalTester universe.
If something is explicitly open source and does not belong to one of the other categories it is to be placed here.

If the allocation of the repository has been decided upon the outcome also defines the suffix to be used for the repository name, i.e. its directory name or path.
The prefix in general can be selected freely but should resemble the product it is part of and its general purpose.
The repository com.hjp.persosim.simulator.protocols.ca3 e.g. describes a closed source addition (com.hjp) to the open source _PersoSim_ project.
Further more it is part of PersoSim's _simulator_ core adding a certain protocol named ca3.

Naming conventions for projects
-------------------------------

When creating a new project it first of all must be given a directory and a project name.
The project's directory name is represented by the name of the directory the project is stored in.
The project name is represented by the value identified by the (first) "name" tag within the project's .project file.

The project's directory name consists of a prefix, an infix and a suffix.
The prefix must be the name of the parent repository.
The infix can be selected freely.
The suffix should be selected from one of the following categories:

* doc [Doc]
	this category contains documentation
* feature [Feature]
	this category contains configurations required for automatically building a feature
* integrationtest [Integration Test]
	this category contains integration tests
* product [Product]
	this category contains configurations required for automatically building a product
* releng [Releng]
	this category contains configurations as well as documentation for building and testing a product
* sample [Sample]
	this category contains samples
* scripts [Scripts]
	this category contains configurations for packing GlobalTester test scripts
* site [Site]
	this category contains configurations for building an eclipse update site
* test [Test]
	this category contains unit tests
* tools [Tools]
	this category contains tools which may be useful for developing, testing or releasing the projects
* ui [UI]
	this category contains user interface specific code
* ui.test [UI Test]
	this category contains ui-specific unit tests
* ui.integrationtest [UI Integration Test]
	this category contains ui-specific integration tests

Extensions and/or modifications to this list are possible in general but should at least be thoroughly discussed by all developers.
Each repository also must contain one project with the same directory name as its repository, i.e. a base project.

For the actual project name we differentiate between "code" and "script" projects.
The project name of code projects is to match the project's directory name.
For script projects the project name is to resemble the project's purpose while
still being human readable.

Naming conventions for bundles
------------------------------

If a project is to contain a bundle its configuration is stored within the META-INF/MANIFEST.MF file.
For the MANIFEST.MF the following conventions must be kept:
* the "Bundle-SymbolicName" must match the directory name of the project
* the "Bundle-Vendor" must be consistent within all bundles and is supposed to be "HJP Consulting GmbH"
* the "Bundle-Name" value must be human readable and reflect the content of Bundle-SymbolicName

While Bundle-Name in general can be selected quite freely it is tied to the Bundle-SymbolicName concerning prefix, infix and suffix.

Prefix:
* if Bundle-SymbolicName starts with "org.globaltester", Bundle-Name is to start with "GT"
* if Bundle-SymbolicName starts with "de.eprsosim", Bundle-Name is to start with "PersoSim"
* if Bundle-SymbolicName starts with "com.hjp.globaltester", Bundle-Name is to start with "GT" or "Extensions to GT"
* if Bundle-SymbolicName starts with "com.hjp.persosim", Bundle-Name is to start with "PersoSim" or "Extensions to PersoSim"

Infix:
Can be selected freely but must reflect the Bundle-SymbolicName

Suffix:
* if one of the suffixes stated under "Naming conventions for projects" is used the suffix must be its human readable representation listed in [] behind it. Bas bundles with same Bundle-SymbolicName as their root project do not possess a suffix and hence are not required to add a suffix.


Further conventions
-------------------

* all repositories are to contain a .gitignore file
* all repositories are to contain a .gitattributes file
