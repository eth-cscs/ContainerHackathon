#!/bin/bash

in=$1
elapsed=`grep 'timing step' $in |head -74 |tail -50 |awk '{s=s+$5}END{print s}'`
echo $in $elapsed 50
