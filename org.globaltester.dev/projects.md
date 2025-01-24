Projects overview
===
This file gives you an overview of the projects managed by secunet. Some of the mentioned projects are available as open source software, while others are proprietary. 
It focuses on the relevant top level projects, describes their scope and development entrypoint. It will *not* describe each single project repository, for that information look in the README files provided within these repositories and contained projects.

GlobalTester
------------
Product release engineering repositories:  
`com.secunet.globaltester.prove.epa`  
`com.secunet.globaltester.prove.epa.poseidas`  
`com.secunet.globaltester.prove.epareader`  
`com.secunet.globaltester.prove.epp`  
`com.secunet.globaltester.prove.idl`  
`com.secunet.globaltester.prove.is`  

GlobalTester is an Open Source test tool for conformance testing and analysis of smart cards, such as electronic identification cards (eID) and electronic passports (ePassports) as well as related document readers.

PersoSim
--------
Product release engineering repository:  
`de.persosim.rcp`  

PersoSim the open source eID simulator. See [http://www.persosim.de] for more details.
Development entrypoint is the Eclipse Rich Client Platform project 'de.persosim.rcp'. Inside of that repository you will find a releng project which contains a maven aggregator build definition which build the product to an executable. Within your Eclipse workspace you can open the product definition file in 'de.persosim.rcp.product' and create/launch a new launch configuration from there.

POSeIDAS
--------
Product release engineering repository:  
`com.secunet.poseidas`  

POSeIDAS implements additional features for PersoSim, the open source eID simulator. See [http://www.persosim.de] for more details.
These are implemented according to TR-03110 and are used to simulate functionalities of eIDAS tokens.
Start development/exploration in the repository 'com.secunet.poseidas'. Inside of that repository you will find a releng project which contains a maven aggregator build definition which builds the product to an executable. Within your Eclipse workspace you can open the product definition file in 'com.secunet.poseidas.product' and create/launch a new launch configuration from there.
