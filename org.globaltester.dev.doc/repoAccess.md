Repository access
=================
We use gitolite to serve our own git repositories. It is located at git.globaltester.org. Some parts of our software are additionally available as Github repositories. This document describes how to use it to retrieve repositories and publish own changes.

Getting access
--------------
When you read this you already have some kind of access ;-)
In order to get access to git.globaltester.org a server admin needs to register an ssh public key and associate it with appropriate access rights. Contact us if you feel you need different access or another key.

Determine access
----------------
Github repositories are generally readable to everyone. When you have access to git.globaltester.org you will be able to execute the command
'ssh git@git.globaltester.org info' to retrieve repositories accessible with your key.
It will give you an output like this:

>hello amay
>
> R W	org.globaltester.dev
> R W	de.persosim.rcp
> R W	de.persosim.simulator

From the second word in the first line you can see the user name associated with your key (you might need that later)

The later lines show you which repositories are available (visible) to you. 

Access rights
-------------
Gitolite only restricts writing access. This means if you can read a repository you can see all branches in it. This implies when you publish a user branch (see below) you must be aware that everybody (with read access on that repo) can see it.

Write access in our configuration generally means you are allowed to manage your own user branches.
User branches have the form /usr/<username>/whateveryoulike. You may create, delete, push any of your own user branches, even non-fastforward pushes are allowed on your own user branches.
So you can do any development you wish on your own branches. In order to get them merged easily try to create separate branches for different features.

secunet developers have a little more rights and are allowed to push (fast-forward) commits on all available branches. This allows them to put review commit even on other users branches (without the otherwise needed detour through their own user branch) and to merge branches into master.

Any other access will require the help of a server admin.
