CURRENT_FILE=$1

if [ ! "$CURRENT_FILE" ]
then
	echo "Missing parameter: File to check"
	exit 1
fi

#Check for lines containing an uneven number of quotation marks

awk 'BEGIN{print "count", "lineNum"}{print gsub(/\"/,"") "\t" NR}' "$CURRENT_FILE" | tail -n +2 | while read CURRENT_LINE
do
	NUMBER_OF_LINE=`echo "$CURRENT_LINE" | cut -f 2`
	NUMBER_OF_QUOTES=`echo "$CURRENT_LINE" | cut -f 1`
	
	if [ $((NUMBER_OF_QUOTES % 2)) -eq 1 ]
	then
		FOUND_UNEVEN_NUMBER=1
		echo "$CURRENT_FILE" : "$NUMBER_OF_LINE" 
	fi
done
