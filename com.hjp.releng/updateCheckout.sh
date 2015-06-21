#!/bin/bash

CHECKOUTSCRIPT=checkout.bat

#collect required repositories from pom.xml
#sed '/<module>/!d;s@</module>@@;/.site/d;/.feature/d;s@^.*/@@' pom.xml > $CHECKOUTSCRIPT
sed '/<module>/!d;s@^.*module>../../\(.\+\)/.*</module>@\1@;' pom.xml > $CHECKOUTSCRIPT

# add staticly required repos
echo "org.globaltester.parent" >> $CHECKOUTSCRIPT

#sort and remove duplicates
sort -u $CHECKOUTSCRIPT -o $CHECKOUTSCRIPT

# add git clone command for repositories
sed 's@^@git clone ssh://git\@tourmaline.intranet.hjp-consulting.com/@' -i $CHECKOUTSCRIPT

cat $CHECKOUTSCRIPT
