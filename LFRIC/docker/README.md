# How to build a Docker container of LFRic

A template Dockerfile to build the `LFRic` container is available below:
```
#################################################################################
# LFRic environment: Builds and runs LFRic Gungho benchmark with PSyclone OMP.
# Prerequisites: LFRic build environment built with the system  GCC compiler
                 (version 7.4.0) using Docker template 'lfric_deps.docker' and
                 the relevant installation scripts.
#################################################################################
#
FROM lfric-deps:gnu
#
# Define home and working directories
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
# Path to PSyclone configuration file
ENV PSYCLONE_CONFIG /usr/local/share/psyclone/psyclone.cfg
#
# Adds config file for MPICH for Sarus on Piz Daint
RUN echo "/usr/local/src/gnu_env/usr/lib" > /etc/ld.so.conf.d/mpich.conf \
 && ldconfig
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
# Navigate to "gungho" directory and build application
 && cd LFRic_trunk/gungho \
 && make build -j \
# Navigate to example directory to run the application from
 && cd example
#
# Paths to executables and example directory
ENV PATH $HOME/LFRic_trunk/gungho/bin:$PATH
WORKDIR $HOME/LFRic_trunk/gungho/example
``` 

We have saved the template Dockerfile above as `lfric_gungho.docker` and we built
it with the command below:

```
docker build --network=host --add-host $HOSTNAME:127.0.0.1 -f lfric_gungho.docker -t lfric-gungho:gnu .
```

The template starts the build from the `lfric-deps:gnu` Docker container which
contains the libraries needed by the code: `MPICH`, `YAXT`, `HDF5`, `NetCDF`,
`NetCDF-Fortran`, `NetCDF-C++`, `XIOS` and `pFUnit`. This dependency container
was  built from the script
[lfric_deps.docker](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/lfric_deps.docker)
by running

```
docker build --network=host --add-host $HOSTNAME:127.0.0.1 -f lfric_deps.docker -t lfric-deps:gnu .
```

The scripts that build the libraries are also provided in the repository:
- [install_lfric_env.sh](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/install_lfric_env.sh)
  sets up the environment and builds the dependencies of `LFRic` without the `XIOS`;
- [install_xios_env.sh](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/install_xios_env.sh)
  creates architecture files needed to build `XIOS` and builds `XIOS`.

## Library versions and settings

* All libraries were dynamically linked to make sure that the `LFRic` container
  will use the optimized libraries of the host system: the `install_lfric_env.sh`
  script contains commented out instructions for a static build if required.

* The `MPICH` version used in the current Met Office (MO) `LFRic` build system is 3.3.
  Here we used version 3.1.4 to ensure ABI compatibility with the Cray MPI library available
  on Piz Daint: please have a look at
  [the MPICH Wiki](https://wiki.mpich.org/mpich/index.php/ABI_Compatibility_Initiative)
  for more information on the ABI Compatibility Initiative.

* `HDF5`, `NetCDF`, `NetCDF-Fortran`, `NetCDF-C++` and `pFUnit` are also slightly
   older than in the current MO `LFRic` build system, whereas `YAXT` is the same version.

* [`XIOS`](https://forge.ipsl.jussieu.fr/ioserver) is a tricky beast to build as
  not every revision/release will work with every compiler and/or every compiler release.
  For instance, the MO GCC 6.1.0 environment uses revision 1537 which is too old
  for GCC 7.4.0 used here. Unfortunately, the current `XIOS` trunk produces a build which
  segfaults at runtime for the GCC release and other libraries used in this container.
  There is, however, a relatively recent revision before the segfault bug that
  was appropriate for this container.

* Here we used the same `PSyclone` release (1.7.0) that is used by the current
 `LFRic` trunk (as of 4 December 2019), built with Python 2 environment (the move
  to Python 3 and newest `PSyclone` is under way????). Not every `PSyclone` release
  will work with every `LFRic` trunk revision. The `LFRic` - `PSyclone` compatibility
  table is give in this
  [`LFRic` wiki (requires login)](https://code.metoffice.gov.uk/trac/lfric/wiki/LFRicTechnical/VersionsCompatibility).

## Tips & tricks

* The container tool [Sarus](https://user.cscs.ch/tools/containers/sarus) supported
  on Piz Daint can add the proper hook to the host MPI library if the command
  `ldconfig` has been run to configure dynamic linker run-time bindings. Since we
  have installed the `MPICH` library in a non-default location, the command
  `ldconfig` would not be able to find the library in the custom path within the
  container. Therefore, before running `ldconfig` we added the path of `MPICH` to
  `/etc/ld.so.conf.d/mpich.conf` as in the example below:
  ```
  # Adds config file for MPICH for Sarus on Piz Daint
  RUN echo "/usr/local/src/gnu_env/usr/lib" > /etc/ld.so.conf.d/mpich.conf \
   && ldconfig
  ```
  Please look [here](https://unix.stackexchange.com/questions/425251/using-ldconfig-and-ld-so-conf-versus-ld-library-path)
  for more information.

* Some libraries (e.g. `YAXT`) perform a test run of a minimal MPI code during
  the configure step of the installation procedure: the test might fail within
  the Docker container if the local hostname cannot be resolved correctly. In
  order to do that, the local hostname should be available in the file `/etc/hosts`,
  which can be achieved adding the option `--add-hostname $HOSTNAME:127.0.0.1` to
  Docker build command.
  If this solution does not work, one needs to edit the `/etc/hosts` file of the
  Docker container directly using `docker run` and commit the change with
  `docker commit`, since editing the `/etc/hosts` file is not possible within
  the Dockerfile. For more details, please check
  [this link](https://stackoverflow.com/questions/23112515/mpich2-gethostbyname-failed/23118973).

* Checking out the `LFRic` trunk requires access to the MO
  [`LFRic` repository](https://code.metoffice.gov.uk/trac/lfric/browser/LFRic).

* Once the `LFRic` trunk is checked out, the `Makefile`s of  tested Gungho and
  Gravity Wave applications needed to be modified from
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
  for the build to complete. For this reason we made changes to `Makefile`s
  outside the container and then copied the tarballs into the container.

* By default, running command-line `make` builds `LFRic` with MPI but not OpenMP.
  To enable `PSyclone` OpenMP optimisations, the environment variable
  `LFRIC_TARGET_PLATFORM` was set to `meto-spice` value.

# How to run the LFRic container with Sarus on Piz Daint

## LFRic Gungho benchmark

After creating the Docker image of the `LFRic` Gungho benchmark, you load it with
`sarus` and run it on Piz Daint. The Slurm batch script below can be used as a
template for running the benchmark:
```
#!/bin/bash -l
#SBATCH --job-name=job_name
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH --constraint=gpu
#SBATCH --output=lfric-gungho.%j.out
#SBATCH --error=lfric-gungho.%j.err

module load daint-gpu
module load sarus
module unload xalt
srun sarus run --mount=type=bind,source=$PWD/input/gungho,destination=/usr/local/src/LFRic_trunk/gungho/example \
               --mpi load/library/lfric-gungho:gnu \
               bash -c "export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK && gungho ./gungho_configuration.nml
```

The local folder `input/gungho` contains the namelist `gungho_configuration.nml`
and four mesh files required for the multigrid preconditioner used in Gungho:
`mesh24.nc`, `mesh12.nc`, `mesh6.nc` and `mesh3.nc`.
There is also an `iodef.xml` file required for parallel IO, however it is not used
if the `use_xios_io` flag in the namelist is set to `.false.` as is the case here.

All files are available in the
[Gungho input archive](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/input-gungho.tar.gz)
on this repository.

Below are times for completing the Gungho benchmark on Cray XC50 with different
mesh resolutions, number of nodes, MPI tasks and OpenMP threads.
*Note:* These times ar Slurm completion times so they include overheads of job submission (prologue and epilogue).

`C24` and `C48` mesh configurations were run on 1 compute node (1 and 6 MPI tasks per node, respectively).

| OMP threads  | C24, 1 MPI | C24, 6 MPI  | C48, 1 MPI | C48, 6 MPI  |
| -------------| -----------| ------------| -----------| ------------|
|       1      |  00:08:06  |  00:01:56   |  00:22:51  |  00:05:00   |
|       2      |  00:03:24  |  00:00:57   |  00:13:18  |  00:03:26   |

<table>
    <thead>
        <tr>
            <th rowspan=3>OMP threads</th>
            <th colspan=4>C24, 1 node</th>
        </tr>
        <tr>
            <th colspan=2>LFRic timer</th>
            <th colspan=2>Slurm time</th>
        </tr>
        <tr>
            <th>1 MPI p.n.</th>
            <th>6 MPI p.n.</th>
            <th>1 MPI p.n.</th>
            <th>6 MPI p.n.</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th>1</th>
            <th>328.91 s</th>
            <th>72.22 s</th>
            <th>00:08:06 (486 s)</th>
            <th>00:01:56 (116 s)</th>
        </tr>
        <tr>
            <th>2</th>
            <th>185.56 s</th>
            <th>44.33 s</th>
            <th>00:03:24 (204 s)</th>
            <th>00:00:57 (57 s)</th>
        </tr>
    </tbody>
</table>

<table>
    <thead>
        <tr>
            <th rowspan=3>OMP threads</th>
            <th colspan=4>C48, 1 node</th>
        </tr>
        <tr>
            <th colspan=2>LFRic timer</th>
            <th colspan=2>Slurm time</th>
        </tr>
        <tr>
            <th>1 MPI p.n.</th>
            <th>6 MPI p.n.</th>
            <th>1 MPI p.n.</th>
            <th>6 MPI p.n.</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th>1</th>
            <th>1354.05 s</th>
            <th>280.76 s</th>
            <th>00:22:51 (1371 s)</th>
            <th>00:05:00 (300 s)</th>
        </tr>
        <tr>
            <th>2</th>
            <th>776.13 s</th>
            <th>177.2 s</th>
            <th>00:13:18 (798 s)</th>
            <th>00:03:26 (206 s)</th>
        </tr>
    </tbody>
</table>

`C96` and `C192` mesh configurations were run on 6 compute nodes (6 MPI tasks per node).

| OMP threads  | C96, 6 MPI | C192, 6 MPI  |
| -------------| -----------| -------------|
|       1      |  00:03:33  |  00:13:40    |
|       2      |  00:02:57  |  00:08:57    |


<table>
    <thead>
        <tr>
            <th rowspan=2>OMP threads</th>
            <th colspan=2>C96, 6 nodes, 6 MPI p.n.</th>
            <th colspan=2>C192, 6 nodes, 6 MPI p.n.</th>
        </tr>
        <tr>
            <th colspan=1>`LFRic` timer</th>
            <th colspan=1>Slurm time</th>
            <th colspan=1>`LFRic` timer</th>
            <th colspan=1>Slurm time</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th>1</th>
            <th>194.59 s</th>
            <th>00:03:33 (213 s)</th>
            <th>128.43 s</th>
            <th>00:02:57 (177 s)</th>
        </tr>
        <tr>
            <th>2</th>
            <th>801.52 s</th>
            <th>00:13:40 (204 s)</th>
            <th>517.95 s</th>
            <th>00:08:57 (537 s)</th>
        </tr>
    </tbody>
</table>




`C24` mesh configuration were run on 1 MPI task and on 1, 2 and 4 OpenMP threads:

| OMP threads  | `LFRic` timer | Slurm time       |
|--------------|---------------|------------------|
|       1      |  394.76 s     | 00:06:58 (418 s) |
|       2      |  231.69 s     | 00:04:32 (272 s) |
|       4      |  153.93 s     | 00:03:14 (194 s) |

## LFRic Gravity Wave benchmark

After creating the Docker image of the `LFRic` Gravity Wave benchmark, you load
it with `sarus` and run it on Piz Daint. The Slurm batch script below can be used
as a template for running the Gravity Wave benchmark:
```
#!/bin/bash -l
#SBATCH --job-name=lfric-gwave
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal
#SBATCH --constraint=gpu

module load daint-gpu
module load sarus
module unload xalt
srun sarus run \ 
     --mount=type=bind,source=$PWD/input/gwave,destination=/usr/local/src/LFRic_trunk/gwave/example \
     --mpi load/library/lfric-gwave:gnu \
     bash -c "export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK && gravity_wave ./gravity_wave_configuration.nml"
```
The local folder `input` contains the namelist `gravity_wave_configuration.nml`
and the mesh file `mesh24.nc`: both files are available in the
[Gravity Wave input archive](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/input-gwave.tar.gz)
on this repository.

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
