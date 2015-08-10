Development workflow
====================
This document describes the development workflow HJP uses (internally as well as when cooperating with external developers).

In essence this workflow shall ensure that the latest commits on the master branch of all repositories comply with our quality standards and allow a release at any time.

Development of features (and bugfixes as well) takes place on user branchesi, one branch per feature. These branches are peer reviewed before getting merged onto master. During the review all unit tests are executed as well as all code quality expectations are checked.

Releases
--------
When all desired features are merged into the master a release can be prepared. This requires manual modification of version identifiers (depending on included changes). Essentially the same build as during development. And afterwards an intensive test of the generated products. Detailed description will follow.

