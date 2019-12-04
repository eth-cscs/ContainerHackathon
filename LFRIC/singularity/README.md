# How to build a Singularity container of LFRIC

This is built on previous work using Singularity to create an LFRic build system.
LFRic has a large dependency tree and is currently being developed by a number of users on a variety of systems, from laptops to HPCs.
It is fully described at  https://github.com/NCAS-CMS/LFRic_container

The aim of this project is to:

1) Put the LFRic build environment into a portable package that can be deployed on different x86 target machines to build the LFRic executables. 

2) Produce an executable that is able to make use of local MPI libraries and therefore local fast interconnects.

3) Produce an executable that can be run on the native system with no run-time dependencies on the build environment to minimise the conflict between the packaged libraries and local libraries used for MPI and job control.


It is dependent on Intel Fortran and an MPICH-ABI compliant MPI implementation. 

### Build container

Build the Singularity LFRic build system as described in step 1-4 in https://github.com/NCAS-CMS/LFRic_container then copy to Piz Daint.

### On Piz Daint:
```
unset LD_PRELOAD # There is a general LD_PRELOAD which interferes with Singularity, but isn't required for it.
module swap PrgEnv-cray PrgEnv-intel
module load singularity
svn checkout --username <username> https://code.metoffice.gov.uk/svn/lfric/LFRic/trunk
```

For gungho the Makefile needs to be edited. Change the lines:
```
export EXTERNAL_DYNAMIC_LIBRARIES = yaxt yaxt_c netcdff netcdf hdf5 \
                                    $(CXX_RUNTIME_LIBRARY)
export EXTERNAL_STATIC_LIBRARIES = xios
```
to
```
export EXTERNAL_DYNAMIC_LIBRARIES = 
export EXTERNAL_STATIC_LIBRARIES = yaxt yaxt_c xios netcdff netcdf hdf5_hl hdf5 
 z :libstdc++.a
```

### Start the container
```
singularity shell -B /opt/intel:/opt/intel lfric_usr.sif #Start singularity with bind points for the local Intel compilers.
```

### Inside the container

```
. /opt/intel/compilers_and_libraries_2017.4.196/linux/bin/ifortvars.sh intel64 #Change compilers_and_libraries_2017.4.196 to match the same major number of the Intel compiler used to build the container. Ignore the "WARNING: 'gcc' was not found" message.
. /container/setup #Set up LFRic compile environment
cd trunk/gungho # or to the downloaded location.
make build #Build the main exec.
```
Log out of the container. The executable built inside the container can be run outside the container using the standard slurm submission system.

### Submission.

The following submission script will set up the Intel compiler version used to build the executable, and ensure that the Cray MPICH-ABI libraries are used at run time.
```
#!/bin/bash -l
#SBATCH --job-name="gungho"
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal
#SBATCH --constraint=gpu
#SBATCH --hint=nomultithread
#SBATCH --reservation=esiwace_1
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

module load PrgEnv-intel
module swap intel/19.0.1.144 intel/17.0.4.196
module unload cray-mpich
module load cray-mpich-abi
export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
# The following line should be customised to match the location of wlm_detect on the system.
export LD_LIBRARY_PATH=/opt/cray/wlm_detect/1.3.3-7.0.1.1_4.6__g7109084.ari/lib6
4:$LD_LIBRARY_PATH
export CRAY_ROOTFS=UDI
cd $HOME/trunk/gungho/example
echo $LD_LIBRARY_PATH
ldd ../bin/gungho
srun ../bin/gungho gungho_configuration.nml
```
