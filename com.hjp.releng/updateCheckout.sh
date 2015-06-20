#!/bin/bash

#collect required repositories from pom.xml
sed '/<module>/!d;s@</module>@@;/.site/d;/.feature/d;s@^.*/@@' pom.xml > checkout.bat

# add staticly required repos
echo "org.globaltester.parent" >> checkout.bat

# add git clone command for repositories
sed 's@^@git clone ssh://git\@tourmaline.intranet.hjp-consulting.com/@' -i checkout.bat

#cat checkout.bat
