#! /bin/bash
# collect version information
VERSIONTMP=`mktemp`
BUNDLEVERSIONS=`mktemp`
VERSIONFILE=`mktemp`

#collect and format bundle versions
grep -h -E "Bundle-((Symb)|(Vers))" ./*/*/META-INF/MANIFEST.MF | paste - - | sed -e "s/Bundle-SymbolicName:\s*//;s/Bundle-Version:\s*//;s/;singleton:=true//;s/^/\t\t/" > $VERSIONTMP
while read LINE; do   printf  "%-60s %s\n" $LINE; done < $VERSIONTMP >$BUNDLEVERSIONS
sort -o $BUNDLEVERSIONS $BUNDLEVERSIONS
cat $BUNDLEVERSIONS | tr " " "-" > $VERSIONTMP
cp $VERSIONTMP $BUNDLEVERSIONS
sed -i -e "s/\([^-]\)-/\1 /;s/-\([^-]\)/ \1/" $BUNDLEVERSIONS

#concat all parts of version information
echo -e "Bundle versions\n---------------"> $VERSIONFILE
sed -e "s/^/\t\t/" $BUNDLEVERSIONS >> $VERSIONFILE 
echo -e "\n<p style=\"page-break-after: always\"/>" >> $VERSIONFILE

# aggregate all files and generate html
MDFILE=`mktemp`
echo -e "Release overview\n================"> $MDFILE
echo -e "Environment information\n-----------------"> $MDFILE
echo -e "Date: \`" `date  +%Y-%m-%d` "\`  ">> $MDFILE
echo -e "Executed by: \`" `id -u -n` "\`  " >> $MDFILE
echo -e "Machine: \`" `uname -a` "\`  " >> $MDFILE
echo -e "Java: \`" `java -version 2>&1 | grep build` "\`  " >> $MDFILE
echo -e "\n" >> $MDFILE
cat $VERSIONFILE >> $MDFILE
find ./ -name releaseTests.md -exec cat {} >> $MDFILE \; 
cat com.secunet.globaltester.universe/com.secunet.globaltester.universe.releng/samples/*.md >> $MDFILE

# generate printable html 
HTMLFILE=`mktemp`
markdown $MDFILE > $HTMLFILE
firefox --new-window $HTMLFILE

