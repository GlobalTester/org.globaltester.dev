Projects overview
===
This file gives you an overview of the projects available on this server (and accessible from this releng repository). 
It focuses on the relevant top level projects describe their scope and development entrypoint. It will *not* describe each single project repository, for that information look in the README files provided within these repositories and contained projects.

GlobalTester
------------
GlobalTester is an Open Source test tool for conformance testing and analysis of smart cards, such as electronic identification cards (eID) and electronic passports (ePassports) as well as related document readers.

PersoSim
--------
PersoSim the open source eID simulator. See [http://www.persosim.de] for more details.
Development entrypoint is the Eclipse Rich Client Platform project 'de.persosim.rcp'. Inside of that repository you will find a releng project which contains a maven aggregator build definition which build the product to an executable. Within your Eclipse workspace you can open the product definition file in 'de.persosim.rcp.product' and create/launch a new launch configuration from there.

POSeIDAS
--------
POSeIDAS implements features of PersoSim, the open source eID simulator. See [http://www.persosim.de] for more details.
Start development/exploration in the repository 'com.hjp.poseidas'. Inside of that repository you will find a releng project which contains a maven aggregator build definition which builds the product to an executable. Within your Eclipse workspace you can open the product definition file in 'com.hjp.poseidas.product' and create/launch a new launch configuration from there.
