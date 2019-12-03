#!/bin/bash
#SBATCH --account=jjsc42 
# budget account where contingent is taken from# TASKS = NODES * GPUS_PER_NODE
#SBATCH --nodes=1
# SBATCH --ntasks-per-node=1
# SBATCH --ntasks=1
# can be omitted if --nodes and --ntasks-per-node
# are given
# SBATCH --cpus-per-task=1
# for OpenMP/hybrid jobs only
#SBATCH --output=secjobrun-%j.out
# if keyword omitted: Default is slurm-%j.out in
# the submission directory (%j is replaced by
# the job ID).
#SBATCH --error=secjobrun-%j.err
# if keyword omitted: Default is slurm-%j.out in
# the submission directory.
#SBATCH --time=23:20:00
#SBATCH --gres=gpu:4
#SBATCH --partition=gpus

#SBATCH --mail-user=b.gong@fz-juelich.de
#SBATCH --mail-type=ALL

#create a folder to save the output

module /usr/local/software/jureca/OtherStages
module load Stages/2019a
module load GCCcore/.8.3.0
module load SciPy-Stack/2019a-Python-3.6.8 
module load TensorFlow/1.13.1-GPU-Python-3.6.8
module load Keras/2.2.4-GPU-Python-3.6.8
module load h5py
# *** start of job script ***
# Note: The current working directory at this point is
# the directory where sbatch was executed.
# export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
# *** start of job script ***
# Note: The current working directory at this point is
# the directory where sbatch was executed.
# export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun python3.6 kitti_train.py



