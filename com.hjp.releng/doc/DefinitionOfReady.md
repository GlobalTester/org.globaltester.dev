Definition of Ready
===================
This definition of ready serves us two purposes. It should help the author of issues to provide the needed information in order to get his issue to the ready state while at the same time shall guard the whole team from very vague requests and time consuming discussions.

On the other hand do **not** use the DoR as flimsy excuse not to discuss an issue. If an issue is unclear let the DoR guide you to find missing information.

We use the DoR in two points in our workflow. First it is the gatekeeper for our sprints. Every issue that shall be included in a sprint will be measured against this DoR. Second it is the guideline while evolving and reviewing an issue even before it is discussed with all developers (which is expensive by design).

* __Subject and description__  
The most important thoughts should be spent on the Subject of an issue. It is those few words that will represent the issue whenever we talk about it. Be as bold and short as possible but no shorter.  
Provide a detailed description of the issue. Especially describe the expected behavior.  
    _Known restrictions_  
If there are restrictions imposed on the solution by surrounding code (which must not be changed for one reason or another) or other requirements these should be pointed out in the description.  
    _Reproduction steps_  
If the issue describes an unexpected behavior/bug ensure to provide detailed step-by-step description to reproduce it.  
    _Implementation hints_  
If the discussion about the topic already lead to a proposed solution this should be pointed out in the description as well. If a proposed solution is present also make sure to state how fixed this solution is an whether or under what circumstances it may be altered.

* __Acceptance criteria__  
Every issue shall contain testable acceptance criteria. Here you can define specific tests that should be implemented as well as all other measures that are needed to ensure that the issue is implemented as expected (and stays so).

* __Estimated__
All points above should ensure that the issue is estimable. For an issue to reach the Draft state it must be estimable but not yet estimated. During the sprint planning all developers estimate the issues together and an issue is only ready if it estimated.  

* __Prioritized__
Similar to the requirement for an issue to be estimated it needs to be prioritized in order to be considered as ready. For an issue to reach Draft state  the author shall already indicate a priority for that issue. That priority might change throughout the life cycle of the issue (even multiple priority changes are possible).


