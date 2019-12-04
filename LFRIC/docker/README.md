# How to build a Docker container of LFRIC

A template Dockerfile to build the `LFRIC` container is available below:
```
FROM lfric-deps:gnu
#
################################################################################
# LFRic environment: Settings to run the model with system gcc compiler
################################################################################
#
# Set the compiler environment
ENV COMP_PACKAGE_DIR $HOME/gnu_env
# Set the following environment variables
ENV INSTALL_DIR $COMP_PACKAGE_DIR/usr
ENV BUILD_DIR $COMP_PACKAGE_DIR/build
ENV PFUNIT $INSTALL_DIR
ENV PATH $INSTALL_DIR/bin:$PATH
ENV FC gfortran
ENV FPP "cpp -traditional-cpp"
ENV LDMPI mpif90
ENV FFLAGS "-I$BUILD_DIR/XIOS/inc -I$INSTALL_DIR/include -I$INSTALL_DIR/mod"
ENV LDFLAGS "-L$BUILD_DIR/XIOS/lib -L$INSTALL_DIR/lib -L/usr/lib -lstdc++"
ENV CPPFLAGS "-I$INSTALL_DIR/include -I/usr/include"
ENV LD_LIBRARY_PATH $INSTALL_DIR/lib:$INSTALL_DIR/lib64:$LD_LIBRARY_PATH
ENV PSYCLONE_CONFIG /usr/local/share/psyclone/psyclone.cfg
#
# For most applications one OMP thread is enough
ENV OMP_NUM_THREADS 1
#
# Copy LFRic trunk inside the container
COPY LFRic_trunk.tar .
# Unpack LFRic trunk
RUN tar -xf LFRic_trunk.tar \
# Navigate to "gungho" directory
 && cd LFRic_trunk/gungho \
 && make build -j \
# Navigate to example directory and run application
 && cd example \
# Run in serial
# && ../bin/gungho gungho_configuration.nml \
# Run in parallel
 && $INSTALL_DIR/bin/mpiexec -np 6 ../bin/gungho gungho_configuration.nml

ENV LFRIC_EXEC_PATH $HOME/LFRic_trunk/gungho/bin
``` 
The template starts the build from `lfric-deps:gnu`, which contains the libraries needed by the code: `mpich`, `YAXT`, `HDF5`, `netCDF`, `netCDF-Fortran`, `netCDF-C++`, `XIOS` and `PFUNIT`. The scripts that build the libraries are provided in the repository: 
- [install_lfric_env.sh](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/install_lfric_env.sh) setup the environment and build the dependencies of `LFRIC`
- [make_arch_files.sh] (https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/make_arch_files.sh) creates the architecture files needed to build `XIOS`

# How to run the LFRC container with Sarus on Piz Daint

After creating the Docker image of the `LFRIC` Gravity Wave benchmark, you load it with `sarus` and run it on Piz Daint. The Slurm batch script below can be used as a template for running the Gravity Wave benchmark:
```
#!/bin/bash -l
#SBATCH --job-name=lfric-gwave
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal
#SBATCH --constraint=gpu
#SBATCH --reservation=esiwace_1

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
module load daint-gpu
module load sarus
module unload xalt
srun sarus run --mpi load/library/lfric-gwave:gnu gravity_wave gravity_wave_configuration.nml
```

The Gravity Wave benchmakr on a single MPI task takes around 5 minutes to complete on a single Cray XC50 node:
```
Batch Job Summary Report for Job "lfric-gwave" (18507334) on daint
-----------------------------------------------------------------------------------------------------
             Submit            Eligible               Start                 End    Elapsed  Timelimit
------------------- ------------------- ------------------- ------------------- ---------- ----------
2019-12-04T12:06:36 2019-12-04T12:06:36 2019-12-04T12:06:38 2019-12-04T12:11:50   00:05:12   01:00:00
-----------------------------------------------------------------------------------------------------
Username    Account     Partition   NNodes   Energy
----------  ----------  ----------  ------  --------------
hck01       hck         normal           1   29.18K joules
```
