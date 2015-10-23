#!/bin/bash
#
# Search for aggregator poms (in parent of parent dir), extract modules, 
# include them in pom of current project and update checkout script accordingly
# 

POM=pom.xml
POMHEAD=`mktemp`
POMMODULES=`mktemp`
POMTAIL=`mktemp`
CHECKOUTSCRIPT=checkout/all.bat

# extract all module references from aggregator poms
MODULES=`find ../../ -name $POM -exec grep "<module>" {} \;`

#remove leading whitespace
MODULES=`printf '%s\n' "${MODULES[@]}" | sed -e 's/^[ \t]*//'`

# sort and remove duplicates
MODULES=`printf '%s\n' "${MODULES[@]}" | sort -u`

# remove releng projects
MODULES=`printf '%s\n' "${MODULES[@]}" | grep -v "\.releng<"`

# resolve local relative paths for projects within same repository
MODULES=`printf '%s\n' "${MODULES[@]}" | sed 's@>\.\./\(\(com.*\)\.\(feature\|site\|scripts\)\)<@>../../\2/\1<@'` #known subprojects
MODULES=`printf '%s\n' "${MODULES[@]}" | sed 's@>\.\./\(com.*\)<@>../../\1/\1<@'` #projects named exactly as the repo

# sort and remove duplicates
MODULES=`printf '%s\n' "${MODULES[@]}" | sort -u`

#dump module list to intermediate file
printf '%s\n' "${MODULES[@]}" > $POMMODULES

#indent modules
sed -i "s/^/    /" $POMMODULES

#output intermediate results
#cat $POMMODULES


#extract head and tail from existing pom
sed ':a;N;$!ba;s/<modules>.*/<modules>/g' $POM > $POMHEAD
sed ':a;N;$!ba;s@.*</modules>@  </modules>@g' $POM > $POMTAIL

#concatenate all parts in the right order
cat $POMHEAD $POMMODULES $POMTAIL > $POM

#cleanup
rm $POMHEAD $POMMODULES $POMTAIL




#collect required repositories from $POM
sed '/<module>/!d;s@^.*module>../../\(.\+\)/.*</module>@\1@;' $POM > $CHECKOUTSCRIPT

# add staticly required repos
echo "org.globaltester.parent" >> $CHECKOUTSCRIPT

#sort and remove duplicates
sort -u $CHECKOUTSCRIPT -o $CHECKOUTSCRIPT

# add git clone command for repositories
sed 's@^@git clone git\@git.hjp-consulting.com:@' -i $CHECKOUTSCRIPT

#display final result
#cat $POM
#cat $CHECKOUTSCRIPT
