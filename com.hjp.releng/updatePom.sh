#!/bin/bash
#
# Search for aggregator poms (in parent of parent dir), extract modules and include them in pom of current project
# 

# extract all module references from aggregator poms
MODULES=`find ../../ -name pom.xml -exec grep "<module>" {} \;`

# sort and remove duplicates
MODULES=`echo $MODULES | tr " " "\n" | sort -u`

# remove releng projects
MODULES=`echo $MODULES | tr " " "\n" | grep -v "\.releng<"`

# resolve local relative paths for projects within same repository
MODULES=`echo $MODULES | tr " " "\n" | sed 's@>\.\./\(\(com.*\)\.\(feature\|site\)\)<@>../../\2/\1<@'` #known subprojects
MODULES=`echo $MODULES | tr " " "\n" | sed 's@>\.\./\(com.*\)<@>../../\1/\1<@'` #projects named exactly as the repo

# sort and remove duplicates
MODULES=`echo $MODULES | tr " " "\n" | sort -u`

#dump module list to intermediate file
echo $MODULES | tr " " "\n    " > pom.modules

#indent modules
sed -i "s/^/    /" pom.modules

#output intermediate results
#cat pom.modules


#extract head and tail from existing pom
sed ':a;N;$!ba;s/<modules>.*/<modules>/g' pom.xml > pom.head
sed ':a;N;$!ba;s@.*</modules>@  </modules>@g' pom.xml > pom.tail

#concatenate all parts in the right order
cat pom.head pom.modules pom.tail > pom.xml

#cleanup
rm pom.head pom.modules pom.tail

#display final result
#cat pom.xml
