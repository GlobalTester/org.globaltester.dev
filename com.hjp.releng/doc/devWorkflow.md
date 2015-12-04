Development workflow
====================
This document describes the development workflow HJP uses. We use essentially the same process internally as when cooperating with external developers, see the last section of this document for the differences.

In essence this workflow shall ensure that the latest commits on the master branch of all repositories comply with our quality standards and allow a release at any time.

Development of features (and bugfixes as well) takes place on user branches, one branch per feature. These branches are peer reviewed before getting merged onto master. During the review all unit tests are executed as well as all code quality expectations are checked.

We defined several 


Cooperative process with external developers
--------------------------------------------
As external developers currently don't have web access to our issue tracker and are not integrated in our task distribution efforts (aka sprint planning) the process with them differs slightly. In essence we request from external developers the same quality standards as for our own code and perform the same steps to ensure it. 
We are happy to accompany any external developer through our whole process, but in practice we get to know about external efforts mostly not earlier than with a request to merge some code. In that event we will open an issue in our tracker, try to extract as much info as possible and basically follow the same process as we use internally from that point on.
That means for you: inform us about your work as soon as you like, we will open a ticket for that (on which you can collaborate with us via mail). Based on that ticket complete the task you assigned to you in your own pace and come back to us whenever you need help. If you finished the issue we will be happy to review and merge it if it fulfills our quality standard.

In order to include code from external sources we also need to ensure a license compatible with our usage of our products. Thus we request every external developer to sign a contribution agreement with us. For GlobalTester community customers this is already covered in their contract.
