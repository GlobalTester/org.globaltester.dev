Coding guidelines
=================
We want to reuse excellent work where possible and blends well in the existing infrastructure. Therefore we base all our development guidelines on the well established [https://wiki.eclipse.org/Development_Conventions_and_Guidelines Eclipse development conventions and guidelines](EDC). These themselves build upon [http://java.sun.com/docs/codeconv/index.html Oracle's Code Conventions for the Java Programming Language](JCC). 

The following definitions should clarify some of these definitions and fill some holes. Currently we are not aware of anything that contradicts the above mentioned documents, if so we want to use our own definition from this page, but the reason to contradict prior documents should be stated clearly.

Code formatting
---------------
With regard to code formatting the reference to the Eclipse guidelines allows the simple usage of the integrated code formatter without the need to provide an additional template. Just hit Ctrl-Shift-F from time to time and you should be almost safe (except for cases where you intentionally violate those rules).

Naming conventions
------------------
According to the Java Code Conventions we use CamelCase in entity names. Abbreviations should only be used where they are widely known. If they are used they are treated as single words and so only the first letter is upper case with all following letters lower case. Example: `CommandApdu`

Default implementations to interfaces are named with an `Impl` suffix to the interfaces name. This applies only to cases where the Implementation would have the same name as the interface itself. Example: `DedicatedFileImpl`

Member access
-------------
Member fields in a class can be used by this class directly, without using a corresponding getter/setter.
References to members should be used without explicit `this.` prefix. It is not required if duplicate names in local contexts are avoided, which is bad style anyhow. As exception to this rule it might be useful to use constructor parameters and parameters in setter methods with the same name and type as a member field. This is acceptable iff the constructor/setter is extremely short and basically does no more than assign the parameter to the member.

JavaDoc
-------
As opposed to the JavaDoc chapter in EDC we do not add non-javadoc comments to overridden methods. Instead we use the `@Override`-Annotation wherever possible. This allows to browse for the respective JavaDoc without cluttering the code with nearly empty comments. In cases where an implementation becomes significantly more specific we want to use the @inheritDoc tag to partially add to the existing JavaDoc rather than completely replace it. Example:

/**
  * {@inheritDoc}
  * 
  * new description
  * 
  * @param paramName
  *            selectively overriden parameter description
  */
 @Override
 method header

Everything else is to be stated within inline comments.

Tasks
-----
We make extensive use of the Eclipse Tasks view. This can be used to display all comments containing special flags. To highlight the task character of a comment the flag should come as first word, optionally followed by a developer name/sign to assign a task.
According to the default supported flags within eclipse we use the following

+ **FIXME** something that is bogus and broken, needs immediate care

+ **XXX** something that is bogus but works

+ **XXX DEV** something that needs to be discussed in the next developer meeting

+ **TODO** something that needs to be improved, either in code quality or functionality

Additionally we defined the following own task types
+ **IMPL** for features described in a specification but not yet implemented/needed, 
      most usefully placed in a location that is a good starting point for the implementation of that feature.
      Example: `//IMPL File control information handling as described in ISO7816 5.3.3`

Style
-----
We declare variables when we use them, not as early as possible. This allows to reduce scope easily for instance when some code parts need to be captured within a new loop or a try-catch block. Also it is easier to understand a variable defined with a sensible default value than one defined at the beginning of a method without initialization.


