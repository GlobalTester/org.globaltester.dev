#!/bin/bash
# must be called from root directory
#. org.globaltester.dev/org.globaltester.dev.tools/scripts/helper.sh


function createProductList {

	echo "Create product list"
	echo -en "" > $PRODUCT_LIST


if [ -z "$PERSOSIM_ONLY" ]
then
      echo "\$var is empty"
else
      echo "\$var is NOT empty"
fi



if [ -n "$PERSOSIM_ONLY" ]
		then
			echo "PERSOSIM_ONLY PERSOSIM_ONLY"
			echo de.persosim.rcp >> $PRODUCT_LIST
fi



	echo "Following products will be build:"
	cat  $PRODUCT_LIST
}

unset PERSOSIM_ONLY
echo valhalla of: $PERSOSIM_ONLY

for i in "$@" ; do
echo param: "$i"
    if [[ $i == "--persosim_only" ]] ; then
        echo "Is set!"
        PERSOSIM_ONLY=tttruezdt
        break
    fi
done

echo valllue of: $PERSOSIM_ONLY

if [ -z "$PERSOSIM_ONLY" ]
then
      echo "\$var is empty"
else
      echo "\$var is NOT empty"
fi

createProductList

