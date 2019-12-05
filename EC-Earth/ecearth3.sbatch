#!/bin/bash
  
#SBATCH --job-name="ec-earth"
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=12
#SBATCH --time=1:00:00
#SBATCH --output=slurm-%j.log
#SBATCH --constraint=gpu
#SBATCH --reservation=esiwace_2


module load daint-gpu
module load sarus
module unload xalt/2.7.10
image_name=$1


export DR_HOOK=0
export OMP_NUM_THREADS=1
export GRIB_SAMPLES_PATH=/usr/share/eccodes/ifs_samples/grib1_mlgrib2


srun --multi-prog ec-earth.config

