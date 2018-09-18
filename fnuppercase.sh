#!/bin/bash
# convert file names to uppercase for both files
echo Converting the file names to uppercase ...
for file in Images/* ; 
do      #  convert file names to uppercase
    mv $file ${file^^}
done

for file in Points/* ; 
do      #  convert file names to uppercase
    mv $file ${file^^}
done 
