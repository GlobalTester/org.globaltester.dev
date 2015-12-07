Development workflow
====================
This document describes the development workflow HJP uses. We use essentially the same process internally as when cooperating with external developers, see the last section of this document for the differences.

In essence this workflow shall ensure that the latest commits on the master branch of all repositories comply with our quality standards and allow a release at any time.

To keep the process as consistent as possible we developed a single workflow flowchart:

                       .-----.
                       | New |---------------.
                       '-----'               |
                          |                  |
                          |                  |
                          v                  v
                      .-------.        .----------.
                      | Draft |------->| Rejected |
                      '-------'        '----------'
                          |                  ^
                          |                  |
                          v                  |
                      .-------.              |
                      | Ready |--------------'
                      '-------'
                          |
                          |
                          v
                   .-------------.
          .--------| In progress |
          |        '-------------'
          |         ^     |
          |        /      |
          v       /       |
    .----------. /        |
    | Feedback |/         |
    '----------'          |
          |               |
          |               |
          |               v
          |           .------.
          '---------->| Done |
                      '------'
                          |
                          |
                          v
                     .--------.        .----------.
                     | Review |------->| Resolved |
                     '--------'        '----------'


This describes the most frequently used paths through the workflow (of course we are able to deviate from this but it shouldn't be necessary). In general issues start in the **New** state, where the original author can keep and edit them until he feels comfortable that it meets our [Definition of Ready][DoR]. From the **New** state an issue moves over to **Draft** when it is peer reviewed and the author and reviewer agree that all ready criteria are met beside the point estimation. Issues in the **Draft** state will be considered during sprint planing and estimated by all developers, which allows them to transition to the **Ready** state. Also during sprint planning all issues in the **Ready** state will be considered for the upcoming sprint, prioritized and maybe postponed for a later sprint. When the sprint begins all issues for that sprint should be at least n **Ready** state.

Whoever begins to work on an issue assigns it to himself and moves it to the **In progress** state. While an issue is in progress blockers may arise (e.g. required responses from third parties) the assignee moves the ticket to **Feedback** than and documents the reason for that in the ticket. An issue in **Feedback** state is still assigned to the person who initially worked on it and this person is responsible tho collect the required feedback and restarts work on that ticket as soon as the possible. When all required work on an issue is completed and it matches our [Definition of Done][DoD] the assignees transitions the ticket to state **Done**.

Tickets in state **Done** are pulled regularly by developers, whenever a developer finishes the work on a ticket before starting a new ticket he should check for tickets in state **Done** and review them, this ensures that finished work is incorporated into the master as soon as possible. The reviewer moves the ticket to state **Review** and checks it against our [Definition of Done][DoD] and our [coding guidelines][CodingGuidelines]. The issue remains in the state **Review** until it can be closed, e.g moved to state **Resolved**. This implies that an issue won't transition back to **In progress** even if the review leads to significant rework, this rework should be done by the assignee with help from the reviewer in order to resolve the ticket as soon as possible. That also ensures that the review efforts are not duplicated by other developers who might review that ticket when it transitions to **Done** again after an review.

Tickets are considered as closed in the states **Resolved** and **Rejected**. Both states imply a specific type of solution for that issue: Tickets that are closed as **Resolved** where accepted and most probably code has been implemented. Issues in the state **Rejected** where considered and it was decided not to cover them, the ticket log should give you details about the reason to reject an issue.

Beside the general workflow pointed out above we allow some specific modifications for special issue, e.g. some issue types may skip some steps or my return under specific circumstances. Details we be described in the next section where different issue types and their impact on the workflow are discussed.


Issue tracker mapping
---------------------
In order to differentiate between different types of issues we defined the following four trackers that model different subsets of issue status:


1. __Feature__  
A Feature describes a new piece of functionality that was not present in the product before. It implements the most complete set of ticket status and is the core ticket type for product advancement. The author is responsible for the ticket until it reaches ready state. This means the author tries to fulfill the [Definition of Ready][DoR], finds a reviewer who promotes the issue to state **Draft** and presents the issue in the upcoming sprint planing in order to get it to state **Ready**. From there the team is responsible an whoever begins working on the issue assigns it to himself and takes responsibility from that point on until the issue is closed.

1. __Bug__  
A Bug describes a piece of broken functionality that needs to be fixed. It generally also implements the whole set of ticket status but allows for some shortcuts for quick processing. Most of the time these issues pop up during sprints and sometimes need immediate care. To allow them to be handled immediately (e.g. within the running sprint) they need to pass the initial stages until ready relatively fast. Therefore the author of a Bug tries to fulfill the [Definition of Ready][DoR] as soon as possible and may (if the author expects the bug to be of high priority) try to get a prioritization and estimate from the consent of available developers immediately. If the Bug is not expected to be of high priority it will be handled similar to a Feature and will be discussed in the upcoming sprint planning meetings. 

1. __Hotfix__  
A Hotfix describes a change that is not large enough to justify a Bug or Feature. While implementing other issues we sometimes come across things that can be fixed relatively easy but are not covered by existing issues and don't justify the overhead of creating a new Bug or Feature, e. g. code maintenance. The issues can be created either in status **In progress** or in status **Done**. They are created by the author who is immediately the assignee and describes his reasoning for that change. They should cover only a very small effort and don't generate to much overhead. 

1. __Support__  
A Support issue reflects external requests of any kind. This is mostly a support request retrieved by mail. This issue type only covers the actual communication with the customer and evaluation of the requests. Therefore there is no effort estimation made for Support issues. The workflow is reduced to the states **New**, **In progress**, **Feedback** and **Resolved** or **Rejected**. If the issue points out that it actually describes a bug or feature request (or even multiple of them) the required input is gathered from the customer, according issues are opened in the appropriate tracker and the customer is added as watcher to those issues to be able to see the progress. 

Repository mapping
------------------
As mentioned above development takes place on user branches, one branch per feature/bugfix/issue. These branches are created by the assignee of the issue as soon as the first repository artifact is created. Generally this happens within issue state **In progress**. Immediately before the issue is done the assignee shall rebase it onto the current master (or at least ensure that it can be merged without conflicts). The reviewer takes that branch, merges it onto the current master and reviews it wrt the DoD and our coding guidelines. If the code meets our quality standards that merged master is pushed back to the repos. If the code does not match all quality criteria the reviewer decides together with the assignee whether the merged and reviewed code can be fixed together, should be rejected or can be merged/pushed for others to build upon and the remaining quality issues can be fixed as a HotFix.
We experienced some heavy issues when reviewing/merging in parallel, mostly when several branches touched similar files and did heavy refactoring. Thus we introduced a master token, which grants writing access to the master. So whenever complicated operations on the master are needed you need to obtain that token before and keep it until you finished your push.

Cooperative process with external developers
--------------------------------------------
As external developers currently don't have web access to our issue tracker and are not integrated in our task distribution efforts (aka sprint planning) the process with them differs slightly. In essence we request from external developers the same quality standards as for our own code and perform the same steps to ensure it. 
We are happy to accompany any external developer through our whole process, but in practice we get to know about external efforts mostly not earlier than with a request to merge some code. In that event we will open an issue in our tracker, try to extract as much info as possible and basically follow the same process as we use internally from that point on.
That means for you: inform us about your work as soon as you like, we will open a ticket for that (on which you can collaborate with us via mail). Based on that ticket complete the task you assigned to you in your own pace and come back to us whenever you need help. If you finished the issue we will be happy to review and merge it if it fulfills our quality standard.

In order to include code from external sources we also need to ensure a license compatible with our usage of our products. Thus we request every external developer to sign a contribution agreement with us. For GlobalTester community customers this is already covered in their contract.

[DoR]: DefinitionOfReady.md
[DoD]: DefinitionOfDone.md
[CodingGuidelines]: CodingGuidelines.md
