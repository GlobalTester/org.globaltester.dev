FILENAME=$1

FILE="$(<$FILENAME)";
BYTES="${#FILE}"; 
for ((i=0;i<BYTES;i++))
do
	echo "${FILE:i:1}";
done
