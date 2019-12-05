# How to build a Docker container of LFRic

A template Dockerfile to build the `LFRic` container is available below:
```
################################################################################
# LFRic environment: Settings to run the model with system gcc compiler
#                    Builds and runs LFRic gungho benchmark with PSyclone OMP
################################################################################ 
#
FROM lfric-deps:gnu
#
# Define home
ENV HOME /usr/local/src
WORKDIR /usr/local/src
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
#
# Adds config file for MPICH for Sarus on Piz Daint
RUN echo "/usr/local/src/gnu_env/usr/lib" > /etc/ld.so.conf.d/mpich.conf \
 && ldconfig
#
# Path to PSyclone configuration file
ENV PSYCLONE_CONFIG /usr/local/share/psyclone/psyclone.cfg
#
# For most applications one OMP thread is enough (can be set in batch submit script)
ENV OMP_NUM_THREADS 1
#
# Set option to apply OpenMP optimisations with PSyclone
ENV LFRIC_TARGET_PLATFORM meto-spice
#
# Copy LFRic trunk inside the container
COPY LFRic_trunk.tar .
# Unpack LFRic trunk
RUN tar -xf LFRic_trunk.tar \
# Navigate to "gungho" directory
 && cd LFRic_trunk/gungho \
 && make build -j \
# Navigate to example directory to run the application from
 && cd example
#
# Paths to executables and example directory
ENV PATH $HOME/LFRic_trunk/gungho/bin:$PATH
WORKDIR $HOME/LFRic_trunk/gungho/example
``` 
The template starts the build from the `lfric-deps:gnu` Docker container which contains the libraries needed by the code: `MPICH`, `YAXT`, `HDF5`, `NetCDF`, `NetCDF-Fortran`, `NetCDF-C++`, `XIOS` and `pFUnit`.
The libraries container is created from this template
```
################################################################################
# LFRic environment: Configures and build the LFRic software stack with the
#                    system GCC compiler (version 7.4.0)
################################################################################ 
#
FROM ubuntu:18.04
#
RUN apt-get update \
 && apt-get install -y build-essential gcc g++ gfortran make libtool python \
 python-pip python-setuptools subversion cmake git m4 zlib1g-dev curl libcurl4 \
 libcurl4-openssl-dev automake libtool-bin pkg-config doxygen \
 libtypes-uri-perl liburi-perl \
 wget --no-install-recommends
#
WORKDIR /usr/local/src
#
ENV HOME /usr/local/src
#
# Copy installation script inside the container
# LFRic install script without the XIOS
COPY install_lfric_env.sh .
# Install script for XIOS
# Copy XIOS make config files script
COPY install_xios_env.sh .
#
# Build lfric environment without XIOS
RUN chmod 755 install_lfric_env.sh install_xios_env.sh \
 && ./install_lfric_env.sh \
 && ./install_xios_env.sh
```
The scripts that build the libraries are provided in the repository: 
- [install_lfric_env.sh](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/install_lfric_env.sh) sets up the environment and builds the dependencies of `LFRic` without the `XIOS`;
- [install_xios_env.sh](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/install_xios_env.sh) creates architecture files needed to build `XIOS` and builds `XIOS`.

## Library versions and settings

* All libraries were dynamically linked to make sure that the `LFRic` container will use the optimized libraries of the host system: the `install_lfric_env.sh` script contains commented out instructions for a static build if required.

* The `MPICH` version used in the current Met Office (MO) `LFRic` build system is 3.3. Here we used 3.1.4 for compatibility with Piz Daint libraries.

* `HDF5`, `NetCDF`, `NetCDF-Fortran`, `NetCDF-C++` and `pFUnit` are also slighlty older than in the current MO `LFRic` build system, whereas `YAXT` is the same version.

* [`XIOS`](https://forge.ipsl.jussieu.fr/ioserver) is a tricky beast to build as not every revision/release will work with every compiler and/or every compiler release.
  For instance, the MO GCC 6.1.0 environment uses revision 1537 which is too old for GCC 7.4.0 used here. Unfortunately, the current `XIOS` trunk produces a build which
  segfaults at runtime for the GCC release and other libraries used in this container. There is, however, a relatively recent revision before the segfault bug that
  was appropriate for this container.

* Here we used the same `PSyclone` release (1.7.0) that is used by the current `LFRic` trunk (as of 4 December 2019), built with Python 2 environment (the move to
  Python 3 and newest `PSyclone` is in progress). Not every `PSyclone` release will work with every `LFRic` trunk revision. The `LFRic` - `PSyclone` compatibility
  table is give in this [`LFRic` wiki (requires login)](https://code.metoffice.gov.uk/trac/lfric/wiki/LFRicTechnical/VersionsCompatibility).

## Tips & tricks

* [Sarus](https://user.cscs.ch/tools/containers/sarus) on Piz Daint had issues with locating `MPICH`. Hence, the lines in the first
  Dockerfile above
  ```
  # Adds config file for MPICH for Sarus on Piz Daint
  RUN echo "/usr/local/src/gnu_env/usr/lib" > /etc/ld.so.conf.d/mpich.conf \
   && ldconfig
  ```
  were aded to help locate MPICH libraries (see e.g. [this link])(https://unix.stackexchange.com/questions/425251/using-ldconfig-and-ld-so-conf-versus-ld-library-path). 
  Note, this would normally be achieved by building Docker container with the option
  `--add-hostname $HOSTNAME:127.0.0.1` to `docker build` command. Alternatively it could be done by modifying the `/etc/hosts` file
  in the Docker container as described [here](https://stackoverflow.com/questions/23112515/mpich2-gethostbyname-failed/23118973)
  and the committing the change. However, neither of these solutions worked here.

* Checking out the `LFRic` trunk requires access to the MO [`LFRic` repository](https://code.metoffice.gov.uk/trac/lfric/browser/LFRic).

* Once the `LFRic` trunk is checked out, the `Makefile`s of  tested Gungho and Gravity Wave applications needed to be modified from
  ```
  export EXTERNAL_DYNAMIC_LIBRARIES = yaxt yaxt_c netcdff netcdf hdf5 \
                                      $(CXX_RUNTIME_LIBRARY)
  export EXTERNAL_STATIC_LIBRARIES = xios
  ```
  to
  ```
  export EXTERNAL_DYNAMIC_LIBRARIES =
  export EXTERNAL_STATIC_LIBRARIES = yaxt yaxt_c xios netcdff netcdf hdf5_hl \
                                     hdf5 z :libstdc++.a
  ```
  for the build to complete. For this reason we made changes to `Makefile`s outside the container and then copied the tarballs into the container.

* By default, running command-line `make` builds `LFRic` with MPI but not OpenMP. To enable `PSyclone` OpenMP optimisations, the environment variable
  `LFRIC_TARGET_PLATFORM` was set to `meto-spice` value.

# How to run the LFRic container with Sarus on Piz Daint

## LFRic Gungho benchmark

After creating the Docker image of the `LFRic` Gungho benchmark, you load it with `sarus` and run it on Piz Daint. The Slurm batch script below can be used as a template for running the benchmark:
```
#!/bin/bash -l
#SBATCH --job-name=job_name
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal
#SBATCH --constraint=gpu
#SBATCH --reservation=esiwace_1
#SBATCH --output=lfric-gungho.%j.out
#SBATCH --error=lfric-gungho.%j.err

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
module load daint-gpu
module load sarus
module unload xalt
srun sarus run --mount=type=bind,source=$PWD/input/gungho,destination=/usr/local/src/LFRic_trunk/gungho/example \
               --mpi load/library/lfric-gungho:gnu gungho ./gungho_configuration.nml

```
The local folder `input/gungho` contains the namelist `gungho_configuration.nml` and four mesh files `mesh24.nc`, `mesh12.nc`, `mesh6.nc` and `mesh3.nc`, required
for the multigrid preconditioner used in Gungho. There is also an `iodef.xml` file required for parallel IO, however it is not used if the `use_xios_io` flag
in the namelist is set to `.false.` as is the case here. All files are available in the
[Gungho input archive](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/input-gungho.tar.gz) on this repository.

Below are times for completing the Gungho benchmark on Cray XC50 node with different number of MPI tasks and OpenMP threads.

| OMP threads  | 1 MPI task | 6 MPI tasks |
| -------------| -----------| ------------|
|       1      |  00:06:57  |  00:01:43   |
|       2      |  00:06:55  |  00:01:40   |

## LFRic Gravity Wave benchmark

After creating the Docker image of the `LFRic` Gravity Wave benchmark, you load it with `sarus` and run it on Piz Daint. The Slurm batch script below can be used as a template for running the Gravity Wave benchmark:
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
srun sarus run \ 
     --mount=type=bind,source=/scratch/snx3000/lucamar/lfric/gwave/input,destination=/usr/local/src/gwave \ 
     --mpi load/library/lfric-gwave:gnu gravity_wave ./gravity_wave_configuration.nml
```
The local folder `input` contains the namelist `gravity_wave_configuration.nml` and the mesh file `mesh24.nc`: both files are available in the [Gravity Wave input archive](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/input-gwave.tar.gz) on this repository.

The Gravity Wave benchmark on a single MPI task takes around 5 minutes to complete on a single Cray XC50 node:
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
