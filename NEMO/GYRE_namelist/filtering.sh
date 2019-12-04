#!/bin/bash

in=$1
steps=50
elapsed=`grep 'timing step' $in |head -74 |tail -$steps |awk '{s=s+$5}END{print s}'`
time_per_step=`echo $elapsed $steps |awk '{print $1/$2}'`
echo $in $elapsed $steps $time_per_step
