#!/bin/bash -x
#SBATCH --account=deepacf
#SBATCH --nodes=1
#SBATCH --ntasks=2
##SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --output=pystager-out.%j
#SBATCH --error=pystager-err.%j
#SBATCH --time=00:20:00
#SBATCH --partition=devel
#SBATCH --mail-type=ALL
#SBATCH --mail-user=a.mozaffari@fz-juelich.de
##jutil env activate -p cdeepacf

module --force purge
module /usr/local/software/juwels/OtherStages
module load Stages/2019a
module load Intel/2019.3.199-GCC-8.3.0  ParaStationMPI/5.2.2-1
module load mpi4py/3.0.1-Python-3.6.8



srun python mpi_stager_v2.py
