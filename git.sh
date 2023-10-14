#!/bin/bash

echo  >> 1.txt
git add .
for num in {1,7,55,95}; do
  git commit  --date="$num day ago" -m "bugfix" 1.txt
done

echo "---------Commits done on $num day's ago!----------"