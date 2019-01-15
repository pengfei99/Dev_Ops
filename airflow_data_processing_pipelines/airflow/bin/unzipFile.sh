#!/bin/bash

find $1/Rawdata -type f -name $2'*.gz' | while IFS= read -r file; do

    gunzip "$file"

done 

