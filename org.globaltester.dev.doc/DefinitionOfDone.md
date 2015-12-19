Definition of Done
==================
This page is intended as quick overview of the Definition of Done used throughout the whole GlobaltTester project. All current commiters to GlobalTester agreed on the following definitions and see them as requirements to every part of their work. This ensures overall quality and guarantees a common understanding of how much work is still left to particular tasks.

As the development process evolves this definition should evolve too. So whenever there are any inconsistencies or other issues regarding fulfillment of these definitions, please don't hesitate to discuss them on the next developer meeting or by e-mail. As a rule of thumb before breaking one of these rules it should be discussed and either the rule or the users workflow should be changed (remember that changing this definition still requires consensus among the developers).

In our workflow we defined an issue status **Done**. For a developer to reach that state for his issue the developer ensures to match this definition. During the review this definition is one of the guidelines to check against.

The main idea of a "done" feature should be "potentially shippable". So everything that passes the checks defined in this definition can be included in an upcoming release.


Code quality
------------
Code compiles without compile time errors and mostly without warnings. This means that all appearing compiler warnings should have been dealt with and only those should remain in a commit that are unavoidable by modifications to our code. Suppressing warnings should be used as a last resort only if no other option is available.

Code works as expected, this means at least manually tested and covered by automated unit tests. A single commit should always add some kind of functionality, which not necessarily matches a whole feature or user story. This added value should be very clear from the log message as the subdivision of the feature in several commits is not always obvious. 

Code is readable, this implies a self-review by the commiter just before the commit. Special care should be taken concerning readability of code (including spelling- and grammar checking), documentation including JavaDoc and code comments, speaking names for methods and variables and a descriptive commit comment. For a more detailed description on these topics and the standards we want to use in GlobalTester also see our Development Guidelines.

Code is complete regarding the functionality defined in commit message. This means that all contained code also includes the required error handling, all "Auto-generated ..." Tasks are removed (and handled properly).

The Boy Scout rule states that every part of code that is touched should be commited to the repository in better state than it was checked out from the repository. This especially implies that if understanding some part of the code was difficult this part should be changed (or commented). After all the work of understanding that part is already done, the only work left is to communicate that understanding to the following developers. (This only applies for code touched anyhow. If you stumble across some code that needs maintenance don't hesitate to bring it into better shape but this should not be mixed up with some other commit.) 

History
-------
During development the way to success is not always straight forward. Before a feature is declared "done" it is expected that the history is cleaned up. Every commit should represent a consistent unit of work. Looking on the history you want to find commits that describe the change they introduced together with the reasoning about that. So bugfixes for changes just introduced should be rebased into the original commit as long as the current branch is not merged into master. We expect the message of every commit to be useful and descriptive (even from a future point of view). We allow that single commits don't build correctly (otherwise we would need to cross reference repositories to ensure that a consistent state is checked out).

An issue that is declared done should be rebased on the most recent master branch. This ensures that the merge and review can be performed as smooth as possible. We are aware that due to parallel development this does not ensure that no merges are needed at all, but it significantly decreases the the number of merges required and also their complexity by moving most of the work to the actual authors of changes (who are the most involved anyhow).

Stability
-----------
Even after all code and history clean ups the result needs to be buildable. This means the whole maven build for all products is still working and all tests are passed. This includes all existing unit tests as well as the manual tests of affected bundles.
	
Completeness
------------
Desired functionality completely implemented, there should be no open issues, no remaining tasks, no missing parts, no development stubs and so on. 

A Peer Review should have taken place for every part of the new feature including code, tests and documentation. This ensures that the overall quality of our code base always stays in good shape. 
Acceptance tests should exist and be passed. Therefore the tests themselves need to be accepted and it needs to be checked that those tests cover all aspects of the current feature. 

Documentation and UserAssistance needs to be completely written. 
