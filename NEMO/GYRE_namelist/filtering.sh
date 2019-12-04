#!/bin/bash

in=$1
steps=50

# --- time:
elapsed=`grep 'timing step' $in |head -74 |tail -$steps |awk '{s=s+$5}END{print s}'`
time_per_step=`echo $elapsed $steps |awk '{print $1/$2}'`

# --- mpi:
mpi_max_pctg_lnk=`grep 'Waiting lbc_lnk' $in |awk '{print $7}' |sort -nk 1 |tail -1`
mpi_max_pctg_global=`grep 'Waiting  global time' $in |awk '{print $7}' |sort -nk 1 |tail -1`
mpi_max_pct=`echo $mpi_max_pctg_lnk $mpi_max_pctg_global |awk '{print $1+$2}'`
# echo $in $mpi_max_pct $mpi_max_pctg_lnk $mpi_max_pctg_global

echo $in $elapsed $steps $time_per_step $mpi_max_pct
