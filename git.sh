#!/bin/bash
echo "1" >> 1.txt
git add .

for num in $(seq 270 500 | shuf | tail -n1);do
	git commit --date="$num day ago" -m "bugfix"
done

echo "---------commit done in $num day's ago!------------"
