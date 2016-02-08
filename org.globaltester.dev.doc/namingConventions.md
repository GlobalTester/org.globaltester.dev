Naming conventions
==================

This file documents naming conventions to be observed when creating new or modifying existing repositories or projects.

Repository names
----------------

When creating a new or modifying an existing repository it first of all must be allocated to one of the following already existing categories:
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

If the allocation of the repository has been decided upon the outcome also defines the suffix to be used for the repository name, i.e. its path.
The prefix in general can be selected freely but should resemble the product it is part of and its general purpose.
The repository com.hjp.persosim.simulator.protocols.ca3 e.g. describes a closed source addition (com.hjp) to the open source _PersoSim_ project.
Further more it is part of PersoSim's _simulator_ core adding a certain protocol named ca3.

Project names
-------------

When creating a new or modifying an existing project its allocation to a repository must be determined or checked.
The full name/path of the parent repository is to be used as suffix for the project's own sub directory.
As with the repository's naming the project path's infix can be selected freely. The suffix should be selected from one of the following categories. Extensions and/or modifications to this list are possible but should at least be thoroughly discussed by several developers.

* feature
	this category contains configurations required for automatically building a feature
* releng
	this category contains configurations as well as documentation for building and testing a product
* scripts
	this category contains configurations for packing GlobalTester test scripts
* site
	this category contains configurations for building an eclipse update site
* tests
	this category contains unit tests
* test
	duplicate of 'tests', deprecated
* ui
	this category contains user interface specific code

The actual name of the project as denoted by the tag "name" in the project's .project file is to resemble the project's purpose while
still being human readable.