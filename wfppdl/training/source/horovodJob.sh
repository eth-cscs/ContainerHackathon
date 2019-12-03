#!/bin/bash
#SBATCH --account=deepacf 
# budget account where contingent is taken from# TASKS = NODES * GPUS_PER_NODE
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=4
#SBATCH --ntasks=12
# can be omitted if --nodes and --ntasks-per-node
# are given
# SBATCH --cpus-per-task=1
# for OpenMP/hybrid jobs only
#SBATCH --output=horovod-%j.out
# if keyword omitted: Default is slurm-%j.out in
# the submission directory (%j is replaced by
# the job ID).
#SBATCH --error=horovod-%j.err
# if keyword omitted: Default is slurm-%j.out in
# the submission directory.
#SBATCH --time=20:00:00
#SBATCH --gres=gpu:4
#SBATCH --partition=gpus
#SBATCH --mail-user=b.gong@fz-juelich.de
#SBATCH --mail-type=ALL

#create a folder to save the output
jutil env activate -p deepacf
module --force  purge
module load Stages/Devel-2019a
module load GCC/8.3.0
module load MVAPICH2/2.3.2-GDR
module load Stages/2019a
module load Horovod/0.16.2-GPU-Python-3.6.8
module load Keras/2.2.4-GPU-Python-3.6.8

#module load ParaStationMPI/5.2.2-1
#module load h5py/2.9.0-Python-3.6.8
# *** start of job script ***:
# Note: The current working directory at this point is
# the directory where sbatch was executed.
# export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
# *** start of job script ***
# Note: The current working directory at this point is
# the directory where sbatch was executed.
# export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun --cpu_bind=none python3.6 kitti_train_horovod.py
